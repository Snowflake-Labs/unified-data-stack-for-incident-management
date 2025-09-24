-- context variables are populated in the yaml file under scripts/snowflake.yml
use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema dbt_project_deployments;

create or replace task im_root_task_scheduler
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	schedule='USING CRON 1 0 * * * America/Toronto'
	config='{"target": "dev", "select": "+curated_zone+", "eai": "<% ctx.env.external_access_int %>"}'
	as SELECT 1;

create or replace task im_project_compile
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_root_task_scheduler
	as 
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'compile --target '|| _target;

    EXECUTE DBT PROJECT dbt_project_deployments.dbt_incident_management args=:command
    END;
  $$
  ;

create or replace task im_project_run_with_select
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_project_compile
	as 
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select "'|| _dbt_nodes ||'" --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$;

create or replace task im_project_test
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after im_project_compile, im_project_run_with_select
	as 
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'test --select "'|| _dbt_nodes ||'" --target '|| _target;

    EXECUTE dbt project dbt_project_deployments.dbt_incident_management args=:command;
    END;
  $$;