use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- Core model refresh tasks
-- Task to run project dependencies and compile all models, macros, and tests
-- Does not need to be scheduled

create or replace task incm_root_daily_incremental_refresh
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	schedule='<% ctx.env.daily_refresh_cron_schedule %>'
	config='{"target": "<% ctx.env.dbt_target %>"}'
	as SELECT 1;


create or replace task incm_project_compile
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_daily_incremental_refresh
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
      LET command := 'compile --target '|| _target;

      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

create or replace task incm_daily_models_refresh
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_project_compile
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET command := 'run --select tag:daily --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;


-- Triggered Task for document based model refreshes
create or replace task incm_root_triggered_docs_processing
	config='{"target": "<% ctx.env.dbt_target %>"}'
	as SELECT 1;

CREATE OR REPLACE TASK incm_triggered_docs_processing
  warehouse=<% ctx.env.dbt_pipeline_wh %>
  after incm_root_triggered_docs_processing
  WHEN SYSTEM$STREAM_HAS_DATA('INCIDENT_MANAGEMENT.bronze_zone.documents_stream')
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET command := 'run --select tag:document_processing --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;


-- One off operations to deploy Cortex Services and Semantic Views
create or replace task incm_root_deploy_cortex_services
	config='{"target": "<% ctx.env.dbt_target %>"}'
	as SELECT 1;

create or replace task incm_deploy_cortex_services
  warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_deploy_cortex_services
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      
      -- Semantic Views
      LET sv_command := 'run --select semantic_views.incm360 --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:sv_command;

      -- Cortex Search
      LET cs_command := 'run-operation create_document_search_service --args "{service_name: incm_doc_search,search_wh: <% ctx.env.cortex_search_wh %>,search_column: chunk,target_lag:  1 day}" --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:cs_command;
      
      -- Cortex Agents
      LET ca_command := 'run-operation create_cortex_agent --args "{agent_name: incm360_a1, stage_name: <% ctx.env.dbt_project_database %>.gold_zone.agent_specs, spec_file: incm360_agent_1.yml}" --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:ca_command;
    END;
  $$
  ;

