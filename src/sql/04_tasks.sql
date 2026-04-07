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
	config='{"dbt_project_name": "<% ctx.env.dbt_project_name %>", "target": "<% ctx.env.dbt_target %>"}'
	as SELECT 1;


create or replace task incm_project_compile
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_daily_incremental_refresh
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'compile --target '|| SYSTEM$GET_TASK_GRAPH_CONFIG('target');

      EXECUTE DBT PROJECT SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name') args=:command;
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
      LET command := 'run --select tag:daily --target '|| SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name') args=:command;
    END;
  $$
  ;


-- Triggered Task for document based model refreshes
create or replace task incm_root_triggered_docs_processing
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	config='{"dbt_project_name": "<% ctx.env.dbt_project_name %>", "target": "<% ctx.env.dbt_target %>"}'
  WHEN SYSTEM$STREAM_HAS_DATA('INCIDENT_MANAGEMENT.bronze_zone.documents_stream')
	as SELECT 1;

CREATE OR REPLACE TASK incm_triggered_docs_processing
  warehouse=<% ctx.env.dbt_pipeline_wh %>
  after incm_root_triggered_docs_processing
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run --select tag:document_processing --target '|| SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name') args=:command;
    END;
  $$
  ;

-- DAG 3: Triggered task graph for Cortex Services and Semantic Views deployment
-- No schedule — invoke manually via: EXECUTE TASK incm_root_deploy_cortex_services;
create or replace task incm_root_deploy_cortex_tools
	warehouse=<% ctx.env.dbt_pipeline_wh %>
	config='{"dbt_project_name": "<% ctx.env.dbt_project_name %>", "target": "<% ctx.env.dbt_target %>", "cortex_search_wh": "<% ctx.env.cortex_search_wh %>", "cortex_search_service_name": "<% ctx.env.cortex_search_service_name %>"}'
	as SELECT 1;

create or replace task incm_deploy_semantic_view
  warehouse=<% ctx.env.dbt_pipeline_wh %>
	after incm_root_deploy_cortex_tools
	as
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run --select semantic_views.incm360 --target '|| SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name') args=:command;
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
      LET command := 'run-operation create_document_search_service --args '||
      '"{' ||
      'service_name: ' || SYSTEM$GET_TASK_GRAPH_CONFIG('cortex_search_service_name') || ', ' ||
      'search_wh: ' || SYSTEM$GET_TASK_GRAPH_CONFIG('cortex_search_wh') || ', ' ||
      'search_column: chunk, ' ||
      'target_lag:  1 day, ' ||
      'embedding_model: snowflake-arctic-embed-l-v2.0' ||
      '}' || ' --target ' || SYSTEM$GET_TASK_GRAPH_CONFIG('target');

      EXECUTE DBT PROJECT SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name') args=:command;
    END;
  $$
  ;

create or replace task incm_deploy_cortex_agent
  warehouse=<% ctx.env.dbt_pipeline_wh %>
  config='{"dbt_project_name": "<% ctx.env.dbt_project_name %>", "target": "<% ctx.env.dbt_target %>", "database": "<% ctx.env.dbt_project_database %>", "schema": "gold_zone", "stage_name": "agent_specs", "agent_spec_file": "incm360_agent_v200.yml"}'
	as
  EXECUTE IMMEDIATE
  $$
  BEGIN
    LET next_version VARCHAR := (SELECT
                          'v' || '_' ||
                          ARRAY_CONSTRUCT(
                              'phoenix','aurora','nebula','titan','vortex','zenith','blaze','comet',
                              'spark','nova','echo','pulse','drift','frost','surge','lunar',
                              'storm','ember','orbit','flare','prism','bolt','crest','dusk',
                              'apex','onyx','reef','haze','peak','glow','rift','wave'
                          )[ABS(MOD(RANDOM(), 32))]::STRING || '_' ||
                          ARRAY_CONSTRUCT(
                              'falcon','panther','dragon','wolf','hawk','tiger','cobra','raven',
                              'shark','eagle','viper','bear','lynx','fox','orca','jaguar',
                              'puma','mantis','osprey','bison','crane','otter','badger','heron'
                          )[ABS(MOD(RANDOM(), 24))]::STRING
                          AS version_name);

    LET db VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('database');
    LET sch VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('schema');
    LET stage VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('stage_name');
    LET spec_file VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('agent_spec_file');
    LET target VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('target');
    LET dbt_project VARCHAR := SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name');

    LET dq VARCHAR := CHR(34);

    LET args_yaml VARCHAR := :dq || '{agent_name: incident_management_agent, ' ||
      'database: ' || :db || ', ' ||
      'schema: ' || :sch || ', ' ||sch
      'stage_name: ' || :stage || ', ' ||
      'agent_spec_file: ' || :spec_file || ', ' ||
      'next_version: ' || :next_version || '}' || :dq;

    LET command VARCHAR := 'run-operation create_cortex_agent --args ' || :args_yaml || ' --target ' || :target;

    LET stmt VARCHAR := 'EXECUTE DBT PROJECT ' || :dbt_project || ' ARGS = ''' || REPLACE(:command, '''', '''''') || '''';

    EXECUTE IMMEDIATE :stmt;
  END;
  $$
  ;

