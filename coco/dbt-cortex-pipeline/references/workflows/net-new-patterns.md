# Net-New Project Patterns

Templates and patterns for scaffolding a new dbt project with Cortex AI
services from scratch.

## Configuration Files

### dbt_project.yml

See `../templates/example-dbt-project.yml`.

### profiles.yml

See `../templates/example-profiles.yml`.

**Snowflake-native deployment rules:** No `password`, no `authenticator`,
no `env_var()`. `account`/`user` can be empty strings. `profiles.yml`
must be inside the project directory.

### packages.yml

Must include `Snowflake-Labs/dbt_semantic_view`, pinned to the latest
release version (`snow dbt list-packages --like 'dbt_semantic_view'`).

### macros/generate_schema_name.sql

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set default_schema = target.schema -%}
  {%- if custom_schema_name is none -%}
    {{ default_schema }}
  {%- else -%}
      {{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
```

This override ensures that `+schema: gold_zone` creates a schema named
exactly `gold_zone` rather than `<target_schema>_gold_zone`.

## sources.yml

Use standard dbt `sources.yml` format.

## Bronze-Layer Model Pattern

One model per source table. Pass-through or light filtering.

```sql
-- models/bronze_zone/<entity>.sql
{{
    config(
        materialized='table',
        description='Raw <entity> data from source',
        tags=['daily']
    )
}}

SELECT
    column_1,
    column_2,
    -- List specific columns rather than SELECT *
    column_n
FROM {{ source('<source_name>', '<TABLE_NAME>') }}
```

### Document Qualifying View (Bronze)

**Prerequisite: Stream on Stage Directory Table**

The qualifying view reads from a stream on a stage directory table for
incremental change tracking. Verify the stream exists:

```sql
SHOW STREAMS IN SCHEMA <DATABASE>.<SCHEMA>;
```

**If no stream exists**, ask user permission, then create:

```sql
ALTER STAGE IF EXISTS <DATABASE>.<SCHEMA>.<STAGE_NAME>
  SET DIRECTORY = (ENABLE = TRUE);
ALTER STAGE <DATABASE>.<SCHEMA>.<STAGE_NAME> REFRESH;
CREATE STREAM IF NOT EXISTS <DATABASE>.<SCHEMA>.<STREAM_NAME>
  ON STAGE <DATABASE>.<SCHEMA>.<STAGE_NAME>;
```

Declare the stream as a source in `sources.yml`. If the user declines,
fall back to a full-scan view over the directory table (remove the
`WHERE METADATA$ACTION != 'DELETE'` filter).

---

Once the stream is confirmed, create the qualifying view that filters by
supported formats:

```sql
-- models/bronze_zone/v_qualify_new_documents.sql
{{
    config(
        materialized='view',
        description='Qualified documents from stage filtered by format',
        tags=['document_processing']
    )
}}

SELECT
    *,
    CASE
        WHEN CONTAINS(relative_path, 'qa') THEN 'question'
        WHEN CONTAINS(relative_path, 'full') THEN 'full'
        ELSE 'other'
    END AS doc_type,
    SPLIT_PART(relative_path, '.', -1) AS extension
FROM {{ source('<source_name>', '<stream_or_directory_table>') }}
WHERE METADATA$ACTION != 'DELETE'
  AND relative_path IS NOT NULL
  AND ARRAY_CONTAINS(
      SPLIT_PART(relative_path, '.', -1)::VARIANT,
      {{ var("supported_doc_formats") }}
  )
  AND size > 0
```

## Silver-Layer Model Patterns

### Incremental Transformation

```sql
-- models/silver_zone/enriched_<entity>.sql
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='<primary_key>',
        merge_update_columns=['updated_at', '<other_columns>'],
        description='Enriched <entity> with joins and calculations',
        tags=['daily']
    )
}}

SELECT
    a.<primary_key>,
    a.column_1,
    b.lookup_value,
    -- Calculated fields
    DATEDIFF('hour', a.created_at, a.resolved_at) AS resolution_hours
FROM {{ ref('<bronze_model>') }} a
LEFT JOIN {{ ref('<other_model>') }} b
    ON a.foreign_key = b.primary_key
{% if is_incremental() %}
WHERE a.updated_at > (
    SELECT COALESCE(MAX(updated_at), DATEADD('day', -1, CURRENT_TIMESTAMP()))
    FROM {{ this }}
)
{% endif %}
```

### Python Model for AI Enrichment (Silver)

Use Python dbt models (Snowpark) for complex AI pipelines like
`AI_EXTRACT`:

See `scripts/example_document_question_extracts.py` for the full Python model template.

The model uses Snowpark to call `AI_EXTRACT` on staged documents. It builds
a response schema dynamically from `dbt_project.yml` meta config and filters
the qualifying view for `doc_type = 'question'`.

Configure the Python model's stage path and extraction schema via
its companion `.yml` file using `config.meta`. See
`../templates/example-document-question-extracts.yml` for the complete template.

## Gold-Layer Model Patterns

### Conformed Fact/Dimension Table

```sql
-- models/gold_zone/<entity>.sql
{{
    config(
        materialized='table',
        description='Curated <entity> with business metrics',
        tags=['daily']
    )
}}

SELECT
    e.<primary_key>,
    e.dimension_1,
    e.dimension_2,
    e.measure_1,
    -- Business logic
    CASE
        WHEN e.status = 'resolved' THEN 'closed'
        ELSE e.status
    END AS normalized_status,
    e.created_at,
    e.updated_at
FROM {{ ref('<silver_model>') }} e
```

### Document Chunking Model (Gold)

For text data that will feed Cortex Search. Uses `AI_PARSE_DOCUMENT`
for parsing and `SPLIT_TEXT_MARKDOWN_HEADER` for chunking:

See `scripts/example_document_full_extracts.sql` for the full model template.

The model uses `AI_PARSE_DOCUMENT` to extract page-by-page content from
staged files, then `SPLIT_TEXT_MARKDOWN_HEADER` to chunk each page into
searchable segments. It is materialized as `incremental` (append-only)
and tagged `document_processing` so the stream-triggered DAG picks it up.

### Data Freshness Monitoring (Gold)

Use Snowflake Data Metric Functions (DMFs) to monitor data freshness
continuously after models are built. This complements dbt tests: tests
gate your pipeline at build time, DMFs monitor data quality continuously
after data lands.

#### Freshness DMF Macro

Create `macros/attach_freshness_dmf.sql` to attach the system
`FRESHNESS` DMF to a table via a post-hook. See
`scripts/example_attach_freshness_dmf.sql` for the full macro source.

The macro:
1. Sets `DATA_METRIC_SCHEDULE` on the table (default: `TRIGGER_ON_CHANGES`)
2. Attaches `SNOWFLAKE.CORE.FRESHNESS` with `ON (<table_fqn>)`

Apply as a post-hook on models that need freshness tracking:

```sql
-- models/gold_zone/<entity>.sql
{{
    config(
        materialized='table',
        description='Curated <entity> with business metrics',
        tags=['daily'],
        post_hook="{{ attach_freshness_dmf(schedule='TRIGGER_ON_CHANGES') }}"
    )
}}

SELECT ...
```

Or apply project-wide to an entire zone in `dbt_project.yml`:

```yaml
models:
  <project_name>:
    gold_zone:
      +post-hook:
        - "{{ attach_freshness_dmf(schedule='TRIGGER_ON_CHANGES') }}"
```

#### Schedule Options

| Schedule                              | Behavior                                        |
|---------------------------------------|-------------------------------------------------|
| `TRIGGER_ON_CHANGES`                  | Evaluates after any DML modifies the table      |
| `60 MINUTE`                           | Evaluates every 60 minutes                      |
| `USING CRON 0 9 * * * America/Chicago`| Evaluates daily at 9 AM Central                 |

`TRIGGER_ON_CHANGES` is recommended for dbt-managed tables since it
aligns evaluation with `dbt run` rebuilds.

#### Freshness Results View

Create a view to surface DMF results for monitored tables. This model
queries `SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS` and filters
by the tables listed in the `dmf_freshness_tables` var:

```sql
-- models/gold_zone/data_freshness_checks.sql
{{
    config(
        materialized='view',
        description='Data freshness monitoring results for tracked tables',
        tags=['data_freshness_checks']
    )
}}

SELECT
    SCHEDULED_TIME,
    MEASUREMENT_TIME,
    TABLE_DATABASE,
    TABLE_SCHEMA,
    TABLE_NAME,
    METRIC_NAME,
    VALUE
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE UPPER(TABLE_NAME) IN ({{ var('dmf_freshness_tables') }})
  AND UPPER(METRIC_NAME) LIKE '%FRESHNESS%'
ORDER BY MEASUREMENT_TIME DESC
```

Add the `dmf_freshness_tables` var to `dbt_project.yml` with a list
of uppercase table names to monitor:

```yaml
vars:
  dmf_freshness_tables: ['MY_TABLE']
```

The freshness results view can be included in the Semantic View to
enable natural language queries about data freshness (see
`semantic-view-patterns.md` — METRICS clause).

### Schema YAML Pattern

Create a `.yml` file alongside each model. See
`../templates/example-document-full-extracts.yml` for the document chunking model template.
