use role dbt_projects_admin;
use database incident_management;
use schema DBT_PROJECT_DEPLOYMENTS;

create or replace task DEV_DEMO_PIPELINE_BOOKING_BY_DAY
	warehouse=incident_management_dbt_wh
	schedule='USING CRON 1 0 * * * America/Toronto'
	config='{"target": "dev", "select": "+hotel_count_by_day", "eai": "ALLOW_ALL_EAI"}'
	as SELECT 1;

create or replace task TASK_DBT_COMPILE
	warehouse=incident_management_dbt_wh
	after DEV_DEMO_PIPELINE_BOOKING_BY_DAY
	as BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'compile --target '|| _target;

    EXECUTE DBT PROJECT BOOKING_MANAGEMENT_MAIN args=:command;
    
  END;

create or replace task TASK_DBT_DEPS
	warehouse=incident_management_dbt_wh
	after TASK_DBT_COMPILE
	as BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'deps --target '|| _target;
    
    EXECUTE dbt project BOOKING_MANAGEMENT_MAIN args=:command external_access_integrations = (:_eai);
  END;

create or replace task TASK_DBT_RUN
	warehouse=incident_management_dbt_wh
	after TASK_DBT_TEST
	as BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select "'|| _dbt_nodes ||'" --target '|| _target;
    EXECUTE dbt project BOOKING_MANAGEMENT_MAIN args=:command;
  END;

create or replace task TASK_DBT_TEST
	warehouse=incident_management_dbt_wh
	after TASK_DBT_COMPILE, TASK_DBT_DEPS
	as BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'test --select "'|| _dbt_nodes ||'" --target '|| _target;

    EXECUTE dbt project BOOKING_MANAGEMENT_MAIN args=:command;
  END;