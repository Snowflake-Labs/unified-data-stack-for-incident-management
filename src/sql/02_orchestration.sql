-- context variables are populated in the yaml file under scripts/snowflake.yml
use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema dbt_project_deployments;

alter task if exists im_root_task_scheduler suspend;
alter task if exists im_project_run_select_landing_zone suspend;
alter task if exists im_project_run_select_curated_zone suspend;
alter task if exists im_project_test suspend;
alter task if exists im_project_compile suspend;


create or replace task im_root_task_scheduler
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	schedule='USING CRON 1 0 * * * America/Toronto'
	config='{"target": "dev", "eai": "<% ctx.env.external_access_int %>"}'
	as SELECT 1;

create or replace task im_project_compile
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_root_task_scheduler
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'compile --target '|| _target;

    EXECUTE DBT PROJECT dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$
  ;

create or replace task im_project_run_select_landing_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_project_compile
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select landing_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$;

create or replace task im_project_run_select_curated_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_project_compile, im_project_run_select_landing_zone
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select curated_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$;


create or replace task im_project_test
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_project_compile, im_project_run_select_landing_zone, im_project_run_select_curated_zone
	as
  EXECUTE IMMEDIATE 
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'test --target '|| _target;

    EXECUTE dbt project dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$;


alter task im_project_run_select_landing_zone resume;
alter task im_project_run_select_curated_zone resume;
alter task im_project_test resume;
alter task im_project_compile resume;

alter task im_root_task_scheduler resume;