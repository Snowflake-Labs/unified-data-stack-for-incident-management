# Task Orchestration Patterns

| DAG | Trigger | Purpose |
|-----|---------|---------|
| DAG 1: Scheduled Refresh | CRON schedule | Run daily/hourly tagged models |
| DAG 2: Event-Driven Docs | Stream has data | Process new documents |
| DAG 3: Cortex Deployment | Manual `EXECUTE TASK` | Deploy semantic view + search + agent |

## DAG 1: Scheduled Model Refresh

Runs on a CRON schedule. Compiles the project first, then runs
tagged models.

```sql
-- Root: CRON-scheduled
CREATE OR REPLACE TASK root_daily_refresh
  WAREHOUSE = my_wh
  SCHEDULE = 'USING CRON 1 0 * * * America/Toronto'
  CONFIG = '{"dbt_project_name": "my_project", "target": "dev"}'
  AS SELECT 1;

-- Step 1: Compile (resolves dependencies)
CREATE OR REPLACE TASK project_compile
  WAREHOUSE = my_wh
  AFTER root_daily_refresh
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET _nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
      LET command := 'compile --target '
                     || SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT
        SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name')
        args=:command;
    END;
  $$;

-- Step 2: Run daily-tagged models
CREATE OR REPLACE TASK daily_models_refresh
  WAREHOUSE = my_wh
  AFTER project_compile
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run --select tag:daily --target '
                     || SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT
        SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name')
        args=:command;
    END;
  $$;
```

## DAG 2: Stream-Triggered Document Processing

Runs when new documents appear on a stage (detected via a stream).

```sql
-- Root: triggered by stream
CREATE OR REPLACE TASK root_docs_processing
  WAREHOUSE = my_wh
  CONFIG = '{"dbt_project_name": "my_project", "target": "dev"}'
  WHEN SYSTEM$STREAM_HAS_DATA('<DATABASE>.bronze_zone.documents_stream')
  AS SELECT 1;

-- Child: process document-tagged models
CREATE OR REPLACE TASK docs_processing
  WAREHOUSE = my_wh
  AFTER root_docs_processing
  AS
  EXECUTE IMMEDIATE
  $$
    BEGIN
      LET command := 'run --select tag:document_processing --target '
                     || SYSTEM$GET_TASK_GRAPH_CONFIG('target');
      EXECUTE DBT PROJECT
        SYSTEM$GET_TASK_GRAPH_CONFIG('dbt_project_name')
        args=:command;
    END;
  $$;
```

## DAG 3: Manual Cortex Services Deployment

Invoke with `EXECUTE TASK root_deploy_cortex;`. All child tasks depend
on the root and run in parallel.

See `scripts/example_deploy_cortex_tasks.sql` for the full DAG definition.

## Task Lifecycle Management

Before recreating tasks, suspend them in root-first order:

```sql
-- Suspend root first, then children
ALTER TASK IF EXISTS root_daily_refresh SUSPEND;
ALTER TASK IF EXISTS project_compile SUSPEND;
ALTER TASK IF EXISTS daily_models_refresh SUSPEND;

-- Then CREATE OR REPLACE ...

-- Resume in child-first order after recreation
ALTER TASK daily_models_refresh RESUME;
ALTER TASK project_compile RESUME;
ALTER TASK root_daily_refresh RESUME;
```

## Parameterization

Use `snowflake.yml` environment variables for configurable values:

```sql
CREATE OR REPLACE TASK my_task
  WAREHOUSE = <% ctx.env.dbt_pipeline_wh %>
  SCHEDULE = '<% ctx.env.daily_refresh_cron_schedule %>'
  CONFIG = '{"dbt_project_name": "<% ctx.env.dbt_project_name %>",
             "target": "<% ctx.env.dbt_target %>"}'
  AS SELECT 1;
```

See `../templates/example-snowflake-yml.yml` for the template.
