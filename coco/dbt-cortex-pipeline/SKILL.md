---
name: dbt-cortex-pipeline
description: >
  Build end-to-end dbt pipelines on Snowflake that combine data models with
  Cortex AI services (Semantic Views, Cortex Search, Cortex Agents) in a single
  deployable dbt project. Use this skill whenever the user wants to create a dbt
  project that includes natural language querying, text2sql, document search, or
  a Cortex Agent — whether starting from scratch, extending an existing dbt
  project, or migrating from Dynamic Tables. Also trigger
  when the user mentions: dbt with cortex, dbt with semantic view and agent, dbt
  AI pipeline, dbt with AI_PARSE_DOCUMENT or AI_EXTRACT, dbt + cortex search,
  dbt + cortex analyst, convert dynamic tables to dbt with cortex, scaffold a
  dbt project with an agent, dbt project for structured and unstructured data,
  or any request to build a dbt project that also deploys Cortex AI services.
  Do NOT use this skill for standalone cortex agent creation without dbt,
  standalone semantic view SQL without dbt, debugging existing dbt models,
  deploying an already-built dbt project, or single AI function SQL queries
  without a pipeline.
  # version: 1.0.0  (informational only)
  # Iceberg triggers: dbt with iceberg, iceberg tables in dbt, materialize as
  # iceberg, dbt iceberg pipeline, gold layer iceberg, snowflake managed iceberg
---

# dbt + Cortex AI Pipeline Skill

## Prerequisites

- Snowflake account with permissions for databases, schemas, tables, views, stages, tasks, UDFs
- `snow` CLI installed and configured
- An **external access integration** for egress to `github.com`, `codeload.github.com`, `hub.getdbt.com`

## Pre-Scenario Step: External Access Integration

Ask the user for the name of an existing external access integration
that grants egress to `github.com`, `codeload.github.com`, and
`hub.getdbt.com`.

If the user does not have one, provide this example:

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE NETWORK RULE CONTROL_TOWER.NETWORK.GITHUB_DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('github.com:443', 'hub.getdbt.com:443', 'codeload.github.com:443');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION GITHUB_DBT_ACCESS_INTEGRATION
  ALLOWED_NETWORK_RULES = (CONTROL_TOWER.NETWORK.GITHUB_DBT_NETWORK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = ()
  ENABLED = TRUE
  COMMENT = 'Access to github.com and hub.getdbt.com';
```

Verify `snow` CLI supports `--external-access-integration`:

```bash
snow --version
```

Do **not** proceed until both the integration name and CLI version are confirmed.

## Pre-Scenario Step: Snowflake Intelligence Toggle

Ask the user whether they want to register the Cortex Agent with
**Snowflake Intelligence** (SI).

- **If yes**: Ask for the SI object name. Set:
  - `toggle_si_agent_deployment: true`
  - `snowflake_intelligence_object: '<user-provided name>'`
- **If no** (default): Keep defaults:
  - `toggle_si_agent_deployment: false`
  - `snowflake_intelligence_object: 'SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT'`

## Pre-Scenario Step: Iceberg Table Format Toggle

Ask the user whether they want gold-layer models as
**Snowflake-managed Iceberg tables**.

- **If yes**: Collect these details:
  - **External volume name** — the Snowflake external volume for Iceberg
    storage (e.g., `MY_EXTERNAL_VOLUME`). If the user does not have one,
    provide this example and ask them to create it first:

    ```sql
    CREATE OR REPLACE EXTERNAL VOLUME MY_EXTERNAL_VOLUME
      STORAGE_LOCATIONS = (
        (
          NAME = 'my-s3-location'
          STORAGE_BASE_URL = 's3://<bucket>/<path>/'
          STORAGE_PROVIDER = 'S3'
          STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<account_id>:role/<role_name>'
        )
      );
    ```

  - **Catalog integration name** — the Snowflake catalog integration for
    the built-in Iceberg catalog (e.g., `MY_ICEBERG_CATALOG_INT`). If the
    user does not have one, provide this example:

    ```sql
    CREATE OR REPLACE CATALOG INTEGRATION MY_ICEBERG_CATALOG_INT
      CATALOG_SOURCE = SNOWFLAKE
      TABLE_FORMAT = ICEBERG
      ENABLED = TRUE;
    ```

  - **dbt version check** — confirm the dbt-snowflake adapter is **1.10+**
    (catalog support requirement). Ask the user to verify:

    ```bash
    pip show dbt-snowflake | grep Version
    ```

  Record the external volume and catalog integration names. Set:
  - `iceberg_enabled: true`
  - `iceberg_catalog_name: '<user-provided catalog logical name>'`

- **If no** (default): Set `iceberg_enabled: false`, `iceberg_catalog_name: ''`.

## Scenario Detection

| Scenario           | Workflow                                                     |
| ------------------ | ------------------------------------------------------------ |
| **Net New** — No existing dbt project        | [Scenario 1](#scenario-1-net-new)                      |
| **Extension** — Existing dbt project in a local repo      | [Scenario 2](#scenario-2-extension)                    |
| **Migration (DT)** — Existing Dynamic Table pipeline | [Scenario 3](#scenario-3-dynamic-table-migration)      |

If unclear, ask the user which applies.

**IMPORTANT:** All deployment uses the `dbt-projects-on-snowflake` bundled skill.
You **MUST** load it for any `snow dbt` command.

---

## Scenario 1: Net New

> **GATE:** Complete all pre-scenario steps first.

### Step 1: Gather Data Source Context

Collect information about the user's data:

- **Tables/views** in Snowflake: names, schemas, databases, column descriptions.
If the user points to an existing database/schema, run `SHOW TABLES` and
`DESCRIBE TABLE` to discover the schema.
- **Key entities and relationships**: primary keys, foreign keys, join patterns.
- **Staged files**: Are there PDFs, Word docs, or other unstructured documents
on a Snowflake stage? What stage path? What file formats?
- **Unstructured text in source columns**: If no staged files exist, ask the
user whether any source table already contains a column with unstructured or
semi-structured text (e.g., ticket descriptions, comments, notes, knowledge-base
articles, resolution summaries). If yes, record the source table and column
name — this will drive the Cortex Search decision in Step 7.
- **Business questions**: What questions should the Cortex Agent answer? This can be understood from requirements doc if available.  
This informs the Semantic View dimensions/facts and agent instructions.

If the user provides a requirements document or local files, read them to
extract this context.

**Cortex Search eligibility (record for Step 7):**

| Source data signal | Cortex Search? | Action |
|---|---|---|
| Staged unstructured files (PDF, DOCX, etc.) | Yes | Build document processing models (bronze → silver → gold chunking) and search service |
| No staged files, but user identifies a source column with unstructured text | Yes | Surface that column through a gold-layer model and build search service over it |
| No staged files and no unstructured text columns | No | Skip Cortex Search; agent uses only `cortex_analyst_text_to_sql` |

### Step 2: Scaffold the dbt Project

Read `references/workflows/net-new-patterns.md` for complete file templates and SQL
model patterns. Use the standalone YAML example files as starting templates:

Create these configuration files:

1. **dbt_project.yml** — use `references/templates/example-dbt-project.yml` as template.
  Configure medallion zone layout, `vars` for stage paths and document
  parsing settings if applicable.
2. **profiles.yml** — use `references/templates/example-profiles.yml` as template.
  Use placeholders (no `password` or `env_var()`).
3. **packages.yml** — must include `Snowflake-Labs/dbt_semantic_view`.
  Always look up the latest release version before generating the file
  by running: `snow dbt list-packages --like 'dbt_semantic_view'`, or
  checking the Snowflake-Labs GitHub releases. Pin to that version
  (e.g., `version: "0.3.0"`) rather than leaving it unpinned.
4. **macros/generate_schema_name.sql** that uses the custom schema name directly
  (no target prefix).
5. **models/sources.yml** — standard dbt sources declaration.
6. **catalogs.yml** (if Iceberg enabled) — use
   `references/templates/example-catalogs-yml.yml` as template. Populate
   with the external volume and catalog integration names collected in the
   [Iceberg Table Format Toggle](#pre-scenario-step-iceberg-table-format-toggle)
   pre-scenario step. Also add `+catalog: <iceberg_catalog_name>` to the
   gold-zone config in `dbt_project.yml` so all gold models automatically
   use Iceberg format.

**Vars audit:** After generating `dbt_project.yml`, ensure every `var()`
and `dbt.config.get()` call in scripts has a default declared. Present the
vars table to the user for confirmation.

The current known vars are:

| var name | default | used by |
|---|---|---|
| `docs_stage_path` | `'@<DATABASE>.<SCHEMA>.DOCUMENTS'` | `document_full_extracts.sql`, `document_question_extracts.py` |
| `supported_doc_formats` | `['pdf', 'docx', ...]` | `v_qualify_new_documents` (bronze) |
| `parse_mode` | `"LAYOUT"` | `document_full_extracts.sql` |
| `page_split` | `true` | `document_full_extracts.sql` |
| `max_chunk_size` | `500` | `document_full_extracts.sql` |
| `max_chunk_depth` | `5` | `document_full_extracts.sql` |
| `snowflake_intelligence_object` | `'SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT'` | `create_cortex_agent.sql` |
| `toggle_si_agent_deployment` | `false` | `create_cortex_agent.sql` |
| `dmf_freshness_tables` | `[]` (populate with all gold-zone table names) | `data_freshness_checks.sql`, `attach_freshness_dmf` macro |
| `iceberg_enabled` | `false` | gold-zone model configs, `catalogs.yml` generation |
| `iceberg_catalog_name` | `''` | gold-zone `+catalog` config |

If the project does not use unstructured documents, remove the document-related
vars (`docs_stage_path`, `supported_doc_formats`, `parse_mode`, `page_split`,
`max_chunk_size`, `max_chunk_depth`) and confirm with the user.

### Step 3: Create Bronze-Layer Models

One model per source table. Bronze models are simple pass-throughs or
lightly filtered views over source data.

- Add one model file each for each source table.  
- Use `materialized: table` (or `view` for large raw tables).
- Tag with `['daily']` for scheduled refresh.
- For document stage data, first verify a stream exists on the stage
directory table (see `references/workflows/net-new-patterns.md` — "Prerequisite:
Stream on Stage Directory Table"). **⚠️ CHECKPOINT:** If no stream is found,
ask the user for permission to create one before proceeding. Then create a qualifying
view that filters by supported formats and classifies document types.

### Step 4: Create Silver-Layer Models

Transformations, joins, deduplication, AI enrichment.

- Use `materialized: incremental` with merge strategy where appropriate.
- Include `is_incremental()` guards for efficient refreshes.
- For document data, use `AI_EXTRACT` at this layer to pull structured
answers from documents (e.g., title, author, key topics). This produces
a `document_question_extracts` Python model (Snowpark) — use
`references/templates/example-document-question-extracts.yml` as the
schema YAML template and customize the extraction properties with
domain-specific questions. **Do not** use `AI_PARSE_DOCUMENT` here —
full text parsing and chunking belongs in the gold layer (Step 5).
- Tag with `['daily']` or `['document_processing']` as appropriate.

### Step 5: Create Gold-Layer Models

Curated, business-ready fact and dimension tables.

- Use `materialized: table` for structured gold models.
- Tag with `['daily']`.
- If text/document data exists, create a `document_full_extracts` model
that uses `AI_PARSE_DOCUMENT` + `SPLIT_TEXT_MARKDOWN_HEADER` to parse
and chunk documents for Cortex Search indexing. This model uses
`materialized: incremental` (not `table`) because documents are
append-heavy. See `references/workflows/net-new-patterns.md` for
the chunking pattern and `references/templates/example-document-full-extracts.yml`
for the schema YAML template.
- **Data freshness monitoring:** Create the `attach_freshness_dmf` macro
(see `scripts/example_attach_freshness_dmf.sql`) and a
`data_freshness_checks` view model that queries DMF results. Add
`dmf_freshness_tables` to `dbt_project.yml` vars, populated with all
gold-zone table names. Apply the macro as a `post_hook` on each
monitored model. See `references/workflows/net-new-patterns.md` —
"Data Freshness Monitoring" for the full pattern.
- **Iceberg table format (if enabled):** When the user opted in during the
[Iceberg Table Format Toggle](#pre-scenario-step-iceberg-table-format-toggle)
pre-scenario step, the `+catalog: <iceberg_catalog_name>` config applied at
the gold-zone level in `dbt_project.yml` means individual gold models do
**not** need any extra Iceberg-specific config. Both `materialized: table`
and `materialized: incremental` support Iceberg — no model SQL changes are
needed. Views and semantic views are unaffected. See
`references/workflows/net-new-patterns.md` — "Iceberg Configuration (Gold Zone)"
for details.

### Step 6: Create the Semantic View

Read `references/workflows/semantic-view-patterns.md` for clause guidelines
and `scripts/example_semantic_view.sql` for the full template.

Build `models/semantic_views/<view_name>.sql` over all gold zone tables:

1. List all gold zone tables in the `TABLES()` clause using `{{ ref() }}`.
2. Define `RELATIONSHIPS()` from foreign keys identified in Step 1.
3. Add `FACTS()` for numeric/measure columns (amounts, durations, counts).
4. Add `METRICS()` for computed expressions (optional). Add the
   `data_freshness_checks` model to the `TABLES()` clause and include a
   freshness summary metric.
   See `references/workflows/semantic-view-patterns.md` — METRICS clause.
5. Add `DIMENSIONS()` for categorical/filter columns with `SYNONYMS` that
   capture how users naturally refer to each field and `COMMENT` that lists
   valid values where applicable.

**⚠️ CHECKPOINT:** Present the Semantic View (TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS) to the user for review before proceeding to agent creation.

### Step 7: Create Cortex Search Macro (if applicable)

This step is driven by the **Cortex Search eligibility** determined in
Step 1. Do not scan gold-layer models (they do not exist yet).

**If staged unstructured files were identified in Step 1:**

The document processing models created in Steps 3-5 (bronze qualifying
view → silver `AI_EXTRACT` → gold `AI_PARSE_DOCUMENT` + chunking) will
produce a gold-layer table with a text chunk column. Use that chunk
column as the `search_column`.

Create `macros/create_cortex_search_service.sql`. The macro takes
parameters: `service_name`, `search_wh`, `search_column`, `target_lag`,
`embedding_model`. See `references/workflows/cortex-agent-patterns.md`
for the template.

**If the user identified a source column with unstructured text (no staged files):**

1. Ensure a gold-layer model surfaces that column (it may already be
   included in a pass-through or join model created in Step 5, or create
   a dedicated gold model for it). The column does **not** need chunking
   — Cortex Search handles embedding directly on the raw text.
2. Create `macros/create_cortex_search_service.sql` using the
   user-provided column as the `search_column` parameter. All other
   macro parameters (`service_name`, `search_wh`, `target_lag`,
   `embedding_model`) are the same as the staged-files path.
3. Wire the search service into the Cortex Agent spec as a
   `cortex_search` tool (Step 8).

**If the user confirmed no unstructured text in any form:**

Skip this step. The agent will use only `cortex_analyst_text_to_sql`.

### Step 8: Create Cortex Agent Macro + Spec

Read `references/workflows/cortex-agent-patterns.md` for the complete macro and
spec templates. Use `references/templates/example-agent-spec.yml` as the starting
template for the agent spec YAML.

1. **Ensure the `READ_STAGE_FILE` UDF exists.** The agent deployment macro
  depends on a Python UDF in the `dbt_project_deployments` schema that
  reads files from stages. Check whether it exists; if missing, create it
  using `scripts/example_read_stage_file.sql` as the template. The UDF must be
  created in `<DATABASE>.dbt_project_deployments` (create the schema first
  if it doesn't exist).
2. Create `macros/create_cortex_agent.sql` — the idempotent deployment macro
  that reads a YAML spec from a stage, checks if the agent exists, and
   creates or updates it.
3. Create `cortex_agents/<agent_name>.yml` — copy from
  `references/templates/example-agent-spec.yml` and customize:
  - `models.orchestration`: LLM model (default `claude-haiku-4-5`)
  - `instructions.response`: Response formatting rules
  - `instructions.orchestration`: Role description, tool selection logic
  with concrete examples, domain context (entity types, valid filter
  values, key metrics), business rules, and limitations
  - `tools`: `cortex_analyst_text_to_sql` + `cortex_search` (if applicable)
  - `tool_resources`: Fully qualified Snowflake object names

### Step 9: Create Schema YAML Files

For every model in every layer, create a corresponding `.yml` file with:

- Model description
- Column names and descriptions
- Tests (`not_null`, `unique`, `accepted_values`) where appropriate

### Step 10: Deploy to Snowflake

**⚠️ CHECKPOINT:** Confirm the user is ready to deploy. Summarize the models,
macros, and Cortex services that will be created.

Proceed to [Final Step: Provision Database and Deploy](#final-step-all-scenarios-provision-database-and-deploy).

---

## Scenario 2: Extension

> **GATE:** Complete all pre-scenario steps first.

### Step 1: Explore the Existing Project

Use `fdbt` commands (`info`, `list`, `lineage <model> -u`, `tests coverage`)
to explore the project — see `references/workflows/extension-patterns.md` for the
full workflow.

Also read `dbt_project.yml`, `packages.yml`, `macros/`, and scan `models/`
for the layer organization. Identify:

- What the project's most refined data layer is (gold, marts, presentation)
- What naming conventions and materialization strategies are used
- Whether any text/document models with chunk columns exist
- What schema layout the project uses

### Step 2: Identify Top-Layer Models

Find the most refined models. These will be referenced by the Semantic View.
Look for models in the outermost layer (gold, marts, analytics) that represent
business entities. Read their SQL to understand columns, joins, and relationships.

### Step 3: Add Prerequisites

1. Add `Snowflake-Labs/dbt_semantic_view` to `packages.yml` if missing.
  Look up the latest release version (see Scenario 1 Step 2 item 3)
  and pin to it.
2. Add `semantic_views` section in `dbt_project.yml`
  (see `references/templates/example-dbt-project.yml` for the full layout).
3. Check that `generate_schema_name` macro produces clean schema names.
  If the project uses dbt's default (which prefixes the target schema),
   update or add the override macro.

**⚠️ CHECKPOINT — Vars audit:** If adding `vars` to `dbt_project.yml` (e.g., for
document processing or agent deployment), apply the same cross-referencing check
as Scenario 1 Step 2: scan the sample scripts for all `var()` / `dbt.config.get()`
calls and ensure every referenced var has a default in `dbt_project.yml`. Present
the vars table to the user and confirm defaults before proceeding. See the known
vars table in Scenario 1 Step 2 for the full list.

**Preserve all existing project conventions.** Do not rename models, change
materialization strategies, or alter existing macros.

Also add the `attach_freshness_dmf` macro, `data_freshness_checks` view
model, and `dmf_freshness_tables` var (populated with all top-layer table
names) at this step. See
`references/workflows/net-new-patterns.md` — "Data Freshness Monitoring".

If the user opted in to Iceberg during the
[Iceberg Table Format Toggle](#pre-scenario-step-iceberg-table-format-toggle)
pre-scenario step, also:

1. Create `catalogs.yml` at the project root using
   `references/templates/example-catalogs-yml.yml` as template.
2. Add `+catalog: <iceberg_catalog_name>` to the gold-zone (or equivalent
   top-layer) config in `dbt_project.yml`.
3. Add `iceberg_enabled: true` and `iceberg_catalog_name` to `vars`.

### Step 4: Create the Semantic View

Create `models/semantic_views/<view_name>.sql` referencing the top-layer
models identified in Step 2. Infer TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS from the model schemas. See `references/workflows/semantic-view-patterns.md`
and `scripts/example_semantic_view.sql`.

**⚠️ CHECKPOINT:** Present the Semantic View (TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS) to the user for review before proceeding to agent creation.

### Step 5: Create Cortex Search Macro (if applicable)

Follow the same source-data-driven decision as Scenario 1 Step 7.
Since this is an extension of an existing project, determine eligibility by
inspecting the existing top-layer model SQL (from Step 2) and source
definitions:

- If existing models already process staged documents and produce text
  chunk columns, use that chunk column for the search service.
- If no document processing exists, ask the user whether any source table
  contains a column with pre-extracted unstructured text (e.g., ticket
  descriptions, comments, notes). If yes, ensure a top-layer model
  surfaces that column and use it as the `search_column`.
- If no unstructured text exists in any form, skip Cortex Search.

### Step 6: Create Cortex Agent Macro + Spec

Same as Scenario 1 Step 8. Infer domain context from existing models
rather than requirements docs.

### Step 7: Deploy to Snowflake

**⚠️ CHECKPOINT:** Confirm the user is ready to deploy.

Proceed to [Final Step: Provision Database and Deploy](#final-step-all-scenarios-provision-database-and-deploy).

---

## Scenario 3: Dynamic Table Migration

> **GATE:** Complete all pre-scenario steps first.

### Step 1: Discover Dynamic Tables

Read `references/workflows/migration-patterns.md` for the discovery workflow.

**Ask first:** Does the user have the pipeline SQL in a local repository?
If yes, read those files. If no, query Snowflake:

```sql
SHOW DYNAMIC TABLES IN SCHEMA <database>.<schema>;
```

For each Dynamic Table, get the transformation SQL:

```sql
SELECT GET_DDL('DYNAMIC_TABLE', '<database>.<schema>.<table_name>');
```

Capture: table name, SQL body, TARGET_LAG, upstream dependencies.

### Step 2: Map Lineage DAG

Analyze transformation SQL to reconstruct the dependency graph:

- Tables that SELECT from base tables (no DT references) = **bronze zone**
- Tables that join or transform other DTs = **silver zone**
- Terminal/leaf tables (no downstream DTs depend on them) = **gold zone**

Use `DYNAMIC_TABLE_GRAPH_HISTORY()` if available to understand refresh
dependencies.

### Step 3: Scaffold dbt Project

Same structure as Scenario 1 Step 2.

### Step 4: Convert Each DT to a dbt Model

Use `materialized='dynamic_table'` to preserve the Dynamic Table behavior
(automatic refresh via `TARGET_LAG`) without rewriting as incremental
models. This is a lift-and-shift: keep the SELECT logic and refresh
semantics, replace hardcoded references with `ref()`/`source()`.

For each Dynamic Table:

1. Place the model in the appropriate zone (bronze/silver/gold)
2. Replace hardcoded table references with `{{ ref('model_name') }}` or
  `{{ source('source_name', 'table_name') }}`
3. Add `{{ config() }}` with:
  - `materialized='dynamic_table'`
  - `target_lag='<original_lag>'` — carry over from the original DT
  - `snowflake_warehouse='<warehouse>'` — carry over from the original DT
4. Add a `-- Migrated from: DT_<original_name>` comment

See `references/workflows/migration-patterns.md` for the full `dynamic_table` config
reference, `target_lag` mapping by zone, and `on_configuration_change` options.

**Iceberg note:** The `dynamic_table` materialization also supports Iceberg
format. When the user opted in during the
[Iceberg Table Format Toggle](#pre-scenario-step-iceberg-table-format-toggle)
pre-scenario step, gold-zone dynamic tables will automatically pick up the
`+catalog` config from `dbt_project.yml` — no per-model changes needed.

**Freshness DMF note:** Dynamic tables are physical tables, so the
`attach_freshness_dmf` macro and `post_hook` apply to
`materialized='dynamic_table'` models the same way as `table` or
`incremental`. Include all gold-zone dynamic table names in the
`dmf_freshness_tables` var.

### Steps 5-8: Cortex Services + Deploy

Follow Scenario 1 Steps 6-10 (Semantic View, Cortex Search, Cortex Agent,
Schema YAMLs, Deploy). All checkpoints apply. For task scheduling patterns,
see `references/workflows/task-orchestration-patterns.md`.

---

## Final Step (All Scenarios): Provision Database and Deploy

### 1. Configure `snowflake.yml`

Generate using `references/templates/example-snowflake-yml.yml`. Populate
with database name, warehouse, role, and environment-specific values.

**⚠️ CHECKPOINT:** Present `snowflake.yml` to the user for review before proceeding.

### 2. Create Database and Schemas

Run `scripts/example_sysadmin_objects.sql` (parameterized via `snowflake.yml`).
Creates the database, schemas (BRONZE_ZONE, SILVER_ZONE, GOLD_ZONE,
DBT_PROJECT_DEPLOYMENTS), stages, streams, and ownership grants.
Requires `SYSADMIN` role — if unavailable, ask the user for an existing
database or have an admin run it.

```bash
snow sql -f scripts/example_sysadmin_objects.sql
```

**Iceberg prerequisites (if enabled):** Before proceeding, verify that the
external volume and catalog integration collected during the
[Iceberg Table Format Toggle](#pre-scenario-step-iceberg-table-format-toggle)
pre-scenario step exist in Snowflake:

```sql
SHOW EXTERNAL VOLUMES LIKE '<external_volume_name>';
SHOW CATALOG INTEGRATIONS LIKE '<catalog_integration_name>';
```

If either is missing, ask the user to create them before continuing
(see the example SQL in the pre-scenario step).

### 3. Create the `READ_STAGE_FILE` UDF

Deploy the UDF into the `DBT_PROJECT_DEPLOYMENTS` schema using
`scripts/example_read_stage_file.sql`:

```sql
USE SCHEMA <DATABASE>.DBT_PROJECT_DEPLOYMENTS;
-- Then run the contents of scripts/example_read_stage_file.sql
```

### 4. Deploy the dbt Project

**You MUST load the `dbt-projects-on-snowflake` bundled skill before this step.**

```bash
snow dbt deploy <project_name> \
  --source /path/to/dbt/project \
  --database <DATABASE> \
  --schema DBT_PROJECT_DEPLOYMENTS \
  --external-access-integration <INTEGRATION_NAME>
```

This deploys the project as a Snowflake object. It does **not** execute it.

**⚠️ CHECKPOINT:** Confirm successful deployment:

```bash
snow dbt list --in schema DBT_PROJECT_DEPLOYMENTS --database <DATABASE>
```

### 5. Deploy Task Graphs

Create Snowflake tasks to orchestrate execution. See
`references/workflows/task-orchestration-patterns.md` and
`scripts/example_deploy_cortex_tasks.sql` for templates.

Create up to three independent task DAGs:

**DAG 1: Scheduled Model Refresh** (always)

CRON-scheduled. Root task carries `dbt_project_name` and `target` in `CONFIG`;
child tasks read via `SYSTEM$GET_TASK_GRAPH_CONFIG()`.

- Root: CRON schedule (e.g., daily at midnight)
- Child 1: `dbt compile`
- Child 2: `dbt run --select tag:daily`

**DAG 2: Stream-Triggered Document Processing** (if unstructured documents exist)

Triggered by `SYSTEM$STREAM_HAS_DATA(...)` on a stage directory table.

- Root: stream trigger
- Child: `dbt run --select tag:document_processing`

Skip if no document models.

**DAG 3: Manual Cortex Services Deployment** (always)

No schedule — invoke with `EXECUTE TASK root_deploy_cortex;`.
Children run in parallel (all depend on root only).

- Root: manual trigger with config (database, schema, stage, agent spec file)
- Child 1: `dbt run --select semantic_views.<view_name>`
- Child 2: `dbt run-operation create_cortex_search_service` (if search exists)
- Child 3: `dbt run-operation create_cortex_agent` with random version tag

Parameterize all tasks via `snowflake.yml` env vars (warehouse, schedule,
project name, target).

**Task lifecycle:** Suspend root-first before recreating; resume child-first
after recreation.

**⚠️ CHECKPOINT:** After creating all task DAGs, resume them and confirm
they are active:

```sql
SHOW TASKS IN SCHEMA <DATABASE>.DBT_PROJECT_DEPLOYMENTS;
```

Ask the user to manually trigger DAG 3 to deploy the semantic view and
Cortex Agent for the first time:

```sql
EXECUTE TASK <DATABASE>.DBT_PROJECT_DEPLOYMENTS.ROOT_DEPLOY_CORTEX;
```

---

## Reference Files

Load on demand — only files relevant to the current step.

**Workflows:** `references/workflows/` — `net-new-patterns.md`, `extension-patterns.md`,
`migration-patterns.md`, `semantic-view-patterns.md`, `cortex-agent-patterns.md`,
`task-orchestration-patterns.md`, `conventions.md`

**Templates:** `references/templates/` — `example-agent-spec.yml`, `example-catalogs-yml.yml`,
`example-dbt-project.yml`,
`example-profiles.yml`, `example-document-full-extracts.yml`,
`example-document-question-extracts.yml`, `example-snowflake-yml.yml`

**Scripts:** `scripts/` — `example_sysadmin_objects.sql`, `example_read_stage_file.sql`,
`example_create_cortex_agent.sql`, `example_create_document_search_sevice.sql`,
`example_deploy_cortex_tasks.sql`, `example_document_full_extracts.sql`,
`example_document_question_extracts.py`, `example_semantic_view.sql`,
`example_attach_freshness_dmf.sql`
