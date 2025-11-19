use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-------------------------------------------------
-- Tasks for Incident Management Project
-------------------------------------------------

-- Daily Incremental Root Scheduler
alter task if exists dbt_project_deployments.daily_incremental_root_scheduler suspend;
alter task if exists dbt_project_deployments.im_project_run_select_bronze_zone suspend;
alter task if exists dbt_project_deployments.im_project_run_select_gold_zone suspend;
alter task if exists dbt_project_deployments.im_project_test suspend;
alter task if exists dbt_project_deployments.im_project_compile suspend;


create or replace task dbt_project_deployments.daily_incremental_root_scheduler
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	schedule='USING CRON 1 0 * * * America/Toronto'
	config='{"target": "dev"}'
	as SELECT 1;

create or replace task dbt_project_deployments.im_project_compile
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.daily_incremental_root_scheduler
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'compile --target '|| _target;

    EXECUTE DBT PROJECT dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

create or replace task dbt_project_deployments.im_project_run_select_bronze_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.im_project_compile
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select bronze_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$;

create or replace task dbt_project_deployments.im_project_run_select_gold_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.im_project_compile, dbt_project_deployments.im_project_run_select_bronze_zone
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select gold_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$;


-- create or replace task dbt_project_deployments.im_project_test
-- 	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
-- 	after dbt_project_deployments.im_project_compile, dbt_project_deployments.im_project_run_select_bronze_zone, dbt_project_deployments.im_project_run_select_gold_zone
-- 	as
--   EXECUTE IMMEDIATE 
--   $$
--     BEGIN
--     LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
--     LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
--     LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
--     LET command := 'test --target '|| _target;

--     EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
--     END;
--   $$;

-- Cortex AI service builder