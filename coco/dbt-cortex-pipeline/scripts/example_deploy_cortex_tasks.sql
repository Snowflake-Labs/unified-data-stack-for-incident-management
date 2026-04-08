-- DAG 3: Manual Cortex Services Deployment
-- Invoke with: EXECUTE TASK root_deploy_cortex;
-- Child tasks for semantic view, search service, and agent run in parallel
-- (all depend on the same root, not on each other).

-- Root: manual trigger
CREATE OR REPLACE TASK root_deploy_cortex
  WAREHOUSE = my_wh
  CONFIG = '{
    "dbt_project_name": "my_project",
    "target": "dev",
    "cortex_search_wh": "search_wh",
    "cortex_search_service_name": "my_search_service"
  }'
  AS SELECT 1;

-- Child 1: Deploy Semantic View (runs dbt model)
CREATE OR REPLACE TASK deploy_semantic_view
  WAREHOUSE = my_wh
  AFTER root_deploy_cortex
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run --select semantic_views.<view_name> --target '
                     || SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT
        SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name')
        args=:command;
    END;
  $$;

-- Child 2: Deploy Cortex Search Service (runs dbt macro)
CREATE OR REPLACE TASK deploy_search_service
  WAREHOUSE = my_wh
  AFTER root_deploy_cortex
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run-operation create_cortex_search_service --args '||
        '"{' ||
        'service_name: ' || SYSTEM$GET_TASK_GRAPH_CONFIG('cortex_search_service_name') || ', ' ||
        'search_wh: ' || SYSTEM$GET_TASK_GRAPH_CONFIG('cortex_search_wh') || ', ' ||
        'search_column: chunk, ' ||
        'target_lag: 1 day, ' ||
        'embedding_model: snowflake-arctic-embed-l-v2.0' ||
        '}"' || ' --target ' || SYSTEM$GET_TASK_GRAPH_CONFIG('target');

      EXECUTE DBT PROJECT
        SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name')
        args=:command;
    END;
  $$;

-- Child 3: Deploy Cortex Agent (runs dbt macro)
CREATE OR REPLACE TASK deploy_cortex_agent
  WAREHOUSE = my_wh
  CONFIG = '{
    "dbt_project_name": "my_project",
    "target": "dev",
    "database": "MY_DB",
    "schema": "gold_zone",
    "stage_name": "agent_specs",
    "agent_spec_file": "my_agent_v100.yml"
  }'
  AS
  EXECUTE IMMEDIATE
  $$
  BEGIN
    -- Generate a random version tag for tracking
    LET next_version VARCHAR := (SELECT
      'v_' ||
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

    LET args_yaml VARCHAR := :dq || '{agent_name: my_agent, ' ||
      'database: ' || :db || ', ' ||
      'schema: ' || :sch || ', ' ||
      'stage_name: ' || :stage || ', ' ||
      'agent_spec_file: ' || :spec_file || ', ' ||
      'next_version: ' || :next_version || '}' || :dq;

    LET command VARCHAR := 'run-operation create_cortex_agent --args '
                           || :args_yaml || ' --target ' || :target;

    LET stmt VARCHAR := 'EXECUTE DBT PROJECT ' || :dbt_project
                        || ' ARGS = '''
                        || REPLACE(:command, '''', '''''') || '''';

    EXECUTE IMMEDIATE :stmt;
  END;
  $$;
