use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- ============================================================================
-- Suspend all tasks (root first, then children) before recreating
-- ============================================================================

-- DAG 1: Daily incremental refresh (root first, then children)
ALTER TASK IF EXISTS incm_root_daily_incremental_refresh SUSPEND;
ALTER TASK IF EXISTS incm_project_compile SUSPEND;
ALTER TASK IF EXISTS incm_daily_models_refresh SUSPEND;

-- DAG 2: Triggered docs processing (root first, then children)
ALTER TASK IF EXISTS incm_root_triggered_docs_processing SUSPEND;
ALTER TASK IF EXISTS incm_triggered_docs_processing SUSPEND;

-- DAG 3: Cortex services deployment (root first, then children)
ALTER TASK IF EXISTS incm_root_deploy_cortex_tools SUSPEND;
ALTER TASK IF EXISTS incm_deploy_semantic_view SUSPEND;
ALTER TASK IF EXISTS incm_deploy_search_service SUSPEND;
ALTER TASK IF EXISTS incm_deploy_cortex_agent SUSPEND;

-- ============================================================================
-- Recreate tasks
-- ============================================================================

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
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	config='{"target": "<% ctx.env.dbt_target %>"}'
  WHEN SYSTEM$STREAM_HAS_DATA('INCIDENT_MANAGEMENT.bronze_zone.documents_stream')
	as SELECT 1;

CREATE OR REPLACE TASK incm_triggered_docs_processing
  warehouse=<% ctx.env.dbt_pipeline_wh %>
  after incm_root_triggered_docs_processing
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

-- DAG 3: Triggered task graph for Cortex Services and Semantic Views deployment
-- No schedule — invoke manually via: EXECUTE TASK incm_root_deploy_cortex_services;
create or replace task incm_root_deploy_cortex_tools
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	config='{"target": "<% ctx.env.dbt_target %>"}'
	as SELECT 1;

create or replace task incm_deploy_semantic_view
  warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_deploy_cortex_tools
	as
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET command := 'run --select semantic_views.incm360 --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

create or replace task incm_deploy_search_service
  warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_deploy_cortex_tools
	as
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET command := 'run-operation create_document_search_service --args "{service_name: incm_doc_search,search_wh: <% ctx.env.cortex_search_wh %>,search_column: chunk,target_lag:  1 day, embedding_model: snowflake-arctic-embed-l-v2.0}" --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

create or replace task incm_deploy_cortex_agent
  warehouse=<% ctx.env.dbt_pipeline_wh %>
  config='{"target": "<% ctx.env.dbt_target %>"}'
	as
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
      LET command := 'run-operation create_cortex_agent --args "{agent_name: incident_management_agent, database: <% ctx.env.dbt_project_database %>, schema: gold_zone, stage_name: agent_specs, agent_spec_file: incm360_agent_v100.yml}" --target '|| _target;
      EXECUTE DBT PROJECT <% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

