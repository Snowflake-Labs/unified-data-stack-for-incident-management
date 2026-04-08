# Key Principles and Validation

## Key Principles

1. **Macros for services, materializations for data.** Cortex Search and
   Agent use `run-operation` macros. Semantic Views use the `semantic_view`
   materialization.
2. **Idempotent everything.** Agent macro checks existence; tasks use
   `CREATE OR REPLACE`; updates use `ALTER ... MODIFY LIVE VERSION`.
3. **Separate orchestration concerns.** Daily refresh, event-driven
   processing, and Cortex deployment are independent DAGs.
4. **Agent spec lives outside dbt.** Staged as YAML, read at deploy time
   via a Python UDF.
5. **Semantic View bridges data and AI.** Defines business vocabulary for
   Text2SQL between gold tables and the Cortex Agent.
6. **Auto-detect chunk columns for search.** Scan model columns for text
   chunk patterns to determine Cortex Search need.
7. **Preserve existing conventions.** When extending (Scenario 2), match
   existing naming, tagging, and materialization patterns.
8. **DMFs complement dbt tests.** dbt tests gate at build time; DMFs
   monitor continuously after data lands. Attach via post-hooks, query
   results via a gold-zone view.

## Validation Checklist

### Project Structure
1. All `{{ ref() }}` calls point to existing models
2. `packages.yml` includes `Snowflake-Labs/dbt_semantic_view` (pinned)
3. `dbt_project.yml` has `semantic_views` config block
4. `cortex_agents/` directory contains agent spec YAML

### Agent Spec Integrity
5. Agent spec is well-formed YAML (parse before staging)
6. Spec references correct fully qualified Semantic View and Search service names
7. `tools[].tool_spec.name` entries match `tool_resources` keys

### Infrastructure Dependencies
8. `READ_STAGE_FILE` UDF exists in `<DATABASE>.dbt_project_deployments`
   (create from `scripts/example_read_stage_file.sql` if missing)
9. `dbt_project_deployments` schema exists
10. Agent spec stage exists (e.g., `<DATABASE>.gold_zone.agent_specs`)

### Tag Consistency
11. Every tag in task orchestration SQL (`--select tag:<name>`) has matching
    models; every model tag is selected by at least one task

### Deployment
12. Use `dbt-projects-on-snowflake` bundled skill to deploy and run

### Data Freshness Monitoring (if applicable)
13. If `dmf_freshness_tables` var is set, `data_freshness_checks` model exists
14. If `dmf_freshness_tables` var is set, `attach_freshness_dmf` macro exists
15. Models with freshness post-hooks use `materialized='table'` or
    `materialized='incremental'` (DMFs cannot attach to views)
