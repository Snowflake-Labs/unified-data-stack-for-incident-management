# Migration Patterns

Patterns for migrating Dynamic Table pipelines to dbt with Cortex AI
services.

## Dynamic Table Discovery

### Query Snowflake for Dynamic Tables

```sql
-- List all dynamic tables in a schema
SHOW DYNAMIC TABLES IN SCHEMA <database>.<schema>;

-- Get the full DDL for each dynamic table
SELECT GET_DDL('DYNAMIC_TABLE', '<database>.<schema>.<table_name>');

-- Get refresh configuration and dependencies
SELECT
    name,
    target_lag,
    refresh_mode,
    scheduling_state,
    text AS transformation_sql
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_GRAPH_HISTORY())
WHERE schema_name = '<SCHEMA>';
```

### Parse DDL to Extract Components

For each Dynamic Table DDL, extract:

1. **Table name** — becomes the dbt model name
2. **SELECT body** — becomes the model SQL
3. **TARGET_LAG** — carried over to the `dynamic_table` materialization config
4. **WAREHOUSE** — carried over to the materialization config
5. **Source references** — other tables/DTs referenced in FROM/JOIN clauses

### Using the `dynamic_table` Materialization

Use `materialized='dynamic_table'` for lift-and-shift: keep SELECT logic
and refresh semantics, replace hardcoded references with `ref()`/`source()`.

Example — original DDL:
```sql
CREATE OR REPLACE DYNAMIC TABLE DB.SCHEMA.DT_USER_SESSIONS
  TARGET_LAG = '1 hour'
  WAREHOUSE = my_wh
AS
SELECT
    session_id,
    user_id,
    MIN(timestamp) AS session_start,
    MAX(timestamp) AS session_end,
    COUNT(*) AS event_count
FROM DB.SCHEMA.DT_RAW_EVENTS
GROUP BY session_id, user_id;
```

Converts to:
```sql
-- models/silver_zone/user_sessions.sql
{{
    config(
        materialized='dynamic_table',
        target_lag='1 hour',
        snowflake_warehouse='my_wh'
    )
}}
-- Migrated from: DT_USER_SESSIONS

SELECT
    session_id,
    user_id,
    MIN(timestamp) AS session_start,
    MAX(timestamp) AS session_end,
    COUNT(*) AS event_count
FROM {{ ref('raw_events') }}
GROUP BY session_id, user_id
```

### `dynamic_table` Config Reference

| Config Key | Source | Description |
|-----------|--------|-------------|
| `target_lag` | Original DT `TARGET_LAG` | Refresh lag (e.g., `'1 hour'`, `'1 day'`, `'downstream'`) |
| `snowflake_warehouse` | Original DT `WAREHOUSE` | Warehouse for refresh compute |

The `target_lag` value is carried directly from the original Dynamic Table.
`'downstream'` means the DT refreshes only when a downstream DT requests it.

Additional optional config:

```sql
{{
    config(
        materialized='dynamic_table',
        target_lag='downstream',
        snowflake_warehouse='my_wh',
        on_configuration_change='apply'   -- apply | continue | fail
    )
}}
```

- `on_configuration_change='apply'` — dbt will ALTER the Dynamic Table
  in place if `target_lag` or `snowflake_warehouse` changes
- `on_configuration_change='continue'` — dbt logs a warning but leaves
  the existing DT unchanged (safe default)
- `on_configuration_change='fail'` — dbt raises an error if config drifts

### Map Lineage to Zones

```
Level 0 (base tables, no DT deps)  → bronze_zone
Level 1+ (transforms other DTs)    → silver_zone
Terminal nodes (no downstream DTs)  → gold_zone
```

If the chain is only 2 levels deep, skip silver and go bronze → gold.

### TARGET_LAG Mapping by Zone

| Zone | Typical `target_lag` | Rationale |
|------|---------------------|-----------|
| Bronze | `'downstream'` or short lag | Refresh based on downstream demand |
| Silver | `'downstream'` | Refresh only when gold needs it |
| Gold | Original DT's lag | Defines the business refresh SLA |

Preserve `'downstream'` from intermediate DTs; keep explicit lags unless
the user wants to consolidate.

### Reference Replacement

Replace hardcoded table references with dbt constructs:

| Original | Replacement |
|----------|-------------|
| `DB.SCHEMA.DT_<name>` | `{{ ref('<model_name>') }}` |
| `DB.SCHEMA.<base_table>` | `{{ source('<source_name>', '<table>') }}` |

### Text Chunk Detection

When scanning migrated DTs for Cortex Search candidates, look for
DTs that call `SPLIT_TEXT_MARKDOWN_HEADER`, `SPLIT_TEXT_RECURSIVE_CHARACTER`,
or produce columns with chunk-like names.

Example migrated chunk model:
```sql
-- models/silver_zone/product_review_chunks.sql
{{
    config(
        materialized='dynamic_table',
        target_lag='1 day',
        snowflake_warehouse='my_wh',
        tags=['document_processing']
    )
}}
-- Migrated from: DT_PRODUCT_REVIEW_CHUNKS

SELECT
    review_id,
    product_id,
    chunk.value::STRING AS chunk,
    relative_path,
    'txt' AS extension
FROM {{ source('reviews', 'product_reviews') }},
    LATERAL FLATTEN(
        SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER(
            review_text,
            OBJECT_CONSTRUCT('#', 'h1'),
            500,
            3
        )
    ) AS chunk
```

### When NOT to Use `dynamic_table`

- Semantic View models must use `materialized='semantic_view'`
- If the user wants to stop using Dynamic Tables entirely, use `table`
  with tag-based task orchestration instead
