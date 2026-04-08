# Cortex Agent Patterns

## Agent Spec YAML

See `references/templates/example-agent-spec.yml` for the complete template.
When there is no document data for Cortex Search, omit the `cortex_search`
tool entry, its `tool_resources` entry, and search-related instructions.

## Instruction Writing Tips

The `instructions.orchestration` section determines answer quality.

1. **Explicit tool selection** — list question patterns and which tool handles them
2. **Valid filter values** — if the semantic view has fixed values, list them
3. **Multi-tool workflows** — spell out the sequence when both tools are needed
4. **Boundaries** — state what the agent cannot do
5. **Domain context** — entity types, categories, lifecycle states, metrics

## Idempotent Deployment Macro

See `scripts/example_create_cortex_agent.sql` for the full macro source.

Pattern:
1. Reads agent spec YAML from a stage via `READ_STAGE_FILE` UDF
2. Checks if agent exists (`SHOW AGENTS`)
3. New: `CREATE OR REPLACE AGENT ... FROM SPECIFICATION`; existing: `ALTER AGENT ... MODIFY LIVE VERSION SET SPECIFICATION`

**Indentation gotcha:** The `{{ agent_spec['data'][0][0] }}` insertion must
start at column 0 (no leading whitespace) inside `$$` delimiters. Jinja
indentation breaks YAML parsing.

## READ_STAGE_FILE UDF

The macro depends on this Python UDF in `dbt_project_deployments`.
See `scripts/example_read_stage_file.sql` for the source.

## Staging the Agent Spec

```sql
CREATE STAGE IF NOT EXISTS <DATABASE>.gold_zone.agent_specs;
PUT file://<local_path>/cortex_agents/<agent_spec>.yml
    @<DATABASE>.gold_zone.agent_specs/
    AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

## Cortex Search Service Macro

See `scripts/example_create_document_search_sevice.sql` for the full macro source.

Parameters: `service_name`, `search_wh`, `search_column`, `target_lag`,
`embedding_model`.

Customize `ATTRIBUTES` based on available columns:

```sql
ATTRIBUTES RELATIVE_PATH                           -- minimal
ATTRIBUTES RELATIVE_PATH, EXTENSION                -- with file metadata
ATTRIBUTES RELATIVE_PATH, EXTENSION, CATEGORY      -- with business context
```

Customize the `AS (SELECT ...)` source query for your chunked model:

```sql
AS (
  SELECT CHUNK, RELATIVE_PATH, EXTENSION
  FROM {{ ref('<your_chunk_model>') }}
);
```
