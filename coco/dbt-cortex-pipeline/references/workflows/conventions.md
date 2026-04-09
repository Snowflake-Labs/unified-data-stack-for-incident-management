# Validation Checklist

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

### Data Freshness Monitoring
13. `data_freshness_checks` model exists
14. `attach_freshness_dmf` macro exists
15. Models with freshness post-hooks use `materialized='table'`,
    `materialized='incremental'`, or `materialized='dynamic_table'`
    (DMFs cannot attach to views)

### Iceberg Configuration (if applicable)
16. If Iceberg is enabled, `catalogs.yml` exists at project root with valid
    external volume and catalog integration references
17. If Iceberg is enabled, gold-zone config in `dbt_project.yml` includes
    `+catalog: <iceberg_catalog_name>`
18. If Iceberg is enabled, dbt-snowflake adapter version is 1.10+
