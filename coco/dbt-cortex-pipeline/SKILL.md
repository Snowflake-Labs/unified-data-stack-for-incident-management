---
name: dbt-cortex-pipeline
description: >
  Build end-to-end dbt pipelines on Snowflake that combine data models with
  Cortex AI services (Semantic Views, Cortex Search, Cortex Agents) in a single
  deployable dbt project. Use this skill whenever the user wants to create a dbt
  project that includes natural language querying, text2sql, document search, or
  a Cortex Agent — whether starting from scratch, extending an existing dbt
  project, or migrating from Dynamic Tables or Stored Procedures. Also trigger
  when the user mentions: dbt with cortex, dbt with semantic view and agent, dbt
  AI pipeline, dbt with AI_PARSE_DOCUMENT or AI_EXTRACT, dbt + cortex search,
  dbt + cortex analyst, convert dynamic tables to dbt with cortex, convert stored
  procedures to dbt with cortex, scaffold a dbt project with an agent, dbt
  project for structured and unstructured data, or any request to build a dbt
  project that also deploys Cortex AI services. Do NOT use this skill for
  standalone cortex agent creation without dbt, standalone semantic view SQL
  without dbt, debugging existing dbt models, deploying an already-built dbt
  project, or single AI function SQL queries without a pipeline.
  # version: 1.0.0  (informational only)
---

# dbt + Cortex AI Pipeline Skill

Create data pipelines that deploy dbt models and Cortex AI services (Semantic
Views, Cortex Search, Cortex Agents) as a unified dbt project on Snowflake.

## Prerequisites

- Snowflake account with permissions for databases, schemas, tables, views, stages, tasks, UDFs
- A warehouse for dbt and Cortex AI operations
- `snow` CLI installed and configured
- For document processing: a Snowflake stage with uploaded files
- An **external access integration** that allows the deployed dbt project to
  download packages from GitHub and the dbt Hub (required by `dbt deps`)

## Pre-Scenario Step: External Access Integration

**⚠️ CHECKPOINT — Before starting any scenario**, ask the user for the name of
an existing external access integration that grants egress to `github.com`,
`codeload.github.com`, and `hub.getdbt.com`. This is required because the
deployed dbt project runs `dbt deps` inside Snowflake, which must reach
these hosts to download packages such as `dbt_semantic_view`.

If the user does not have one, provide this example and ask them to create it
(or have an ACCOUNTADMIN run it) before proceeding:

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

Record the integration name the user provides — it will be needed in the
`snowflake.yml` configuration during the deploy step via the
`--external-access-integration` option of `snow dbt deploy`.

**⚠️ Snowflake CLI version caveat:** The `--external-access-integration` flag
for `snow dbt deploy` is only available in recent versions of the Snowflake CLI.
Before proceeding, ask the user to verify their installed version:

```bash
snow --version
```

If the version does not support `--external-access-integration`, the user must
upgrade to the latest Snowflake CLI before continuing. Do **not** proceed to any
scenario until both the integration name and CLI version are confirmed.

## Pre-Scenario Step: Snowflake Intelligence Toggle

**⚠️ CHECKPOINT — Before starting any scenario**, ask the user whether they
want to register the Cortex Agent with **Snowflake Intelligence** (SI).

- **If yes**: Ask for the fully qualified name of the Snowflake Intelligence
  object (e.g., `MY_DB.MY_SCHEMA.MY_SI_OBJECT`). Record this value —
  when generating `dbt_project.yml`, set:
  - `toggle_si_agent_deployment: true`
  - `snowflake_intelligence_object: '<user-provided name>'`
- **If no** (default): When generating `dbt_project.yml`, keep the defaults:
  - `toggle_si_agent_deployment: false`
  - `snowflake_intelligence_object: 'SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT'`

These vars control whether `macros/create_cortex_agent.sql` runs the
`ALTER SNOWFLAKE INTELLIGENCE ... ADD AGENT` statement after agent creation.
Do **not** proceed to any scenario until the user has confirmed their choice.

## Scenario Detection

| Scenario           | Workflow                                                     |
| ------------------ | ------------------------------------------------------------ |
| **Net New** — No existing dbt project        | [Scenario 1](#scenario-1-net-new)                      |
| **Extension** — Existing dbt project in a local repo      | [Scenario 2](#scenario-2-extension)                    |
| **Migration (DT)** — Existing Dynamic Table pipeline | [Scenario 3a](#scenario-3a-dynamic-table-migration)    |
| **Migration (SP)** — Existing Stored Procedure pipeline | [Scenario 3b](#scenario-3b-stored-procedure-migration) |

If unclear, ask the user which applies.

**IMPORTANT:** All deployment uses the `dbt-projects-on-snowflake` bundled skill.
You **MUST** load it for any `snow dbt` command.

---

## Scenario 1: Net New

> **GATE:** Do not begin this scenario until both pre-scenario steps are
> complete: [External Access Integration](#pre-scenario-step-external-access-integration)
> and [Snowflake Intelligence Toggle](#pre-scenario-step-snowflake-intelligence-toggle).

Starting fresh. The user has data source descriptions, a requirements doc,
or points to a Snowflake database/schema with existing tables.

### Step 1: Gather Data Source Context

Collect information about the user's data:

- **Tables/views** in Snowflake: names, schemas, databases, column descriptions.
If the user points to an existing database/schema, run `SHOW TABLES` and
`DESCRIBE TABLE` to discover the schema.
- **Key entities and relationships**: primary keys, foreign keys, join patterns.
- **Staged files**: Are there PDFs, Word docs, or other unstructured documents
on a Snowflake stage? What stage path? What file formats?
- **Business questions**: What questions should the Cortex Agent answer? This can be understood from requirements doc if available.  
This informs the Semantic View dimensions/facts and agent instructions.

If the user provides a requirements document or local files, read them to
extract this context.

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

**⚠️ CHECKPOINT — Vars audit:** After generating `dbt_project.yml`, cross-reference
the `vars` section against all sample SQL scripts and Python models that will be
used as templates in later steps. Scan every `var()` and `dbt.config.get()` call
in the scripts under `scripts/` and `references/workflows/` to ensure every
referenced var has a default value declared in `dbt_project.yml`. Present the
user with a table of vars, their default values, and the scripts that use them.
Ask the user to confirm or adjust defaults before proceeding. This prevents
runtime failures from undeclared vars.

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
| `dmf_freshness_tables` | `[]` (commented out) | `data_freshness_checks.sql`, `attach_freshness_dmf` macro |

If the project does not use unstructured documents, remove the document-related
vars (`docs_stage_path`, `supported_doc_formats`, `parse_mode`, `page_split`,
`max_chunk_size`, `max_chunk_depth`) and confirm with the user. If the user
does not need data freshness monitoring, omit the `dmf_freshness_tables` var.

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
- **Data freshness monitoring (optional):** If the user wants continuous
freshness tracking, create the `attach_freshness_dmf` macro
(see `scripts/example_attach_freshness_dmf.sql`) and a
`data_freshness_checks` view model that queries DMF results. Add
`dmf_freshness_tables` to `dbt_project.yml` vars. Apply the macro as
a `post_hook` on each monitored model. See
`references/workflows/net-new-patterns.md` — "Data Freshness Monitoring"
for the full pattern.

### Step 6: Create the Semantic View

Read `references/workflows/semantic-view-patterns.md` for clause guidelines
and `scripts/example_semantic_view.sql` for the full template.

Build `models/semantic_views/<view_name>.sql` over all gold zone tables:

1. List all gold zone tables in the `TABLES()` clause using `{{ ref() }}`.
2. Define `RELATIONSHIPS()` from foreign keys identified in Step 1.
3. Add `FACTS()` for numeric/measure columns (amounts, durations, counts).
4. Add `METRICS()` for computed expressions (optional). If a
   `data_freshness_checks` model exists, add a freshness summary metric.
   See `references/workflows/semantic-view-patterns.md` — METRICS clause.
5. Add `DIMENSIONS()` for categorical/filter columns with `SYNONYMS` that
   capture how users naturally refer to each field and `COMMENT` that lists
   valid values where applicable.

**⚠️ CHECKPOINT:** Present the Semantic View (TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS) to the user for review before proceeding to agent creation.

### Step 7: Create Cortex Search Macro (if applicable)

Scan gold zone models for text chunk columns. Column name heuristic:
`chunk`, `text_chunk`, `content`, `extract`, `body`, `text_content`,
`document_text`, `page_text`, `section_text`, `embedding_text`.

If found, create `macros/create_cortex_search_service.sql`. The macro
takes parameters: `service_name`, `search_wh`, `search_column`,
`target_lag`, `embedding_model`. See `references/workflows/cortex-agent-patterns.md`
for the template.

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

> **GATE:** Do not begin this scenario until both pre-scenario steps are
> complete: [External Access Integration](#pre-scenario-step-external-access-integration)
> and [Snowflake Intelligence Toggle](#pre-scenario-step-snowflake-intelligence-toggle).

An existing dbt project needs Cortex AI services added.

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

If the user wants data freshness monitoring, also add the
`attach_freshness_dmf` macro, `data_freshness_checks` view model, and
`dmf_freshness_tables` var at this step. See
`references/workflows/net-new-patterns.md` — "Data Freshness Monitoring".

### Step 4: Create the Semantic View

Create `models/semantic_views/<view_name>.sql` referencing the top-layer
models identified in Step 2. Infer TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS from the model schemas. See `references/workflows/semantic-view-patterns.md`
and `scripts/example_semantic_view.sql`.

**⚠️ CHECKPOINT:** Present the Semantic View (TABLES, RELATIONSHIPS, FACTS,
DIMENSIONS) to the user for review before proceeding to agent creation.

### Step 5: Create Cortex Search Macro (if applicable)

Scan top-layer models for text chunk columns (same heuristic as Scenario 1
Step 7). If found, create the macro.

### Step 6: Create Cortex Agent Macro + Spec

Same as Scenario 1 Step 8. Infer domain context from existing models
rather than requirements docs.

### Step 7: Deploy to Snowflake

**⚠️ CHECKPOINT:** Confirm the user is ready to deploy.

Proceed to [Final Step: Provision Database and Deploy](#final-step-all-scenarios-provision-database-and-deploy).

---

## Scenario 3a: Dynamic Table Migration

> **GATE:** Do not begin this scenario until both pre-scenario steps are
> complete: [External Access Integration](#pre-scenario-step-external-access-integration)
> and [Snowflake Intelligence Toggle](#pre-scenario-step-snowflake-intelligence-toggle).

Convert a Dynamic Table pipeline to dbt with Cortex AI services.

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

### Steps 5-8: Cortex Services + Deploy

Follow Scenario 1 Steps 6-10 (Semantic View, Cortex Search, Cortex Agent,
Schema YAMLs, Deploy). All checkpoints apply. For task scheduling patterns,
see `references/workflows/task-orchestration-patterns.md`.

---

## Scenario 3b: Stored Procedure Migration

> **GATE:** Do not begin this scenario until both pre-scenario steps are
> complete: [External Access Integration](#pre-scenario-step-external-access-integration)
> and [Snowflake Intelligence Toggle](#pre-scenario-step-snowflake-intelligence-toggle).

Convert a Stored Procedure pipeline to dbt with Cortex AI services.

### Step 1: Discover Stored Procedures

Read `references/workflows/migration-patterns.md` for the discovery workflow.

**Ask first:** Does the user have the procedure source in a local repo?
If yes, read those files. If no, query Snowflake:

```sql
SHOW PROCEDURES IN SCHEMA <database>.<schema>;
SELECT GET_DDL('PROCEDURE', '<database>.<schema>.<proc_name>(<arg_types>)');
```

Capture: procedure name, language (SQL/Python/JavaScript), body, parameters.

### Step 2: Trace Execution Order

Reconstruct the lineage DAG from procedure logic — identify which tables
each procedure reads/writes, map execution order, and identify final
output tables (gold zone candidates).

### Step 3: Scaffold dbt Project

Same structure as Scenario 1 Step 2.

### Step 4: Convert Each SP to dbt Models

- **SQL**: Extract SELECT from INSERT/MERGE/CREATE TABLE, replace table
  references with `{{ ref() }}` / `{{ source() }}`, drop procedural wrapper.
- **Python**: Convert to dbt Python models (Snowpark), replace
  `session.table()` with `dbt.ref()`, replace `write.save_as_table()` with
  `return result`.
- **JavaScript/Java**: Flag for manual conversion; rewrite as SQL if possible.
- Add `-- Migrated from: SP_<original_name>` comment.

See `references/workflows/migration-patterns.md` for detailed conversion patterns.

### Steps 5-8: Cortex Services + Deploy

Follow Scenario 1 Steps 6-10 (Semantic View, Cortex Search, Cortex Agent,
Schema YAMLs, Deploy). All checkpoints apply.

---

## Final Step (All Scenarios): Provision Database and Deploy

Runs last after all models, macros, and specs are generated.

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

Replace `<INTEGRATION_NAME>` with the external access integration name
collected in the [Pre-Scenario Step](#pre-scenario-step-external-access-integration).

This deploys the project as a Snowflake object. It does **not** execute it —
running models, Cortex Search, and the Agent are separate operations afterward.

**⚠️ CHECKPOINT:** Ask the user to confirm successful deployment:

```bash
snow dbt list --in schema DBT_PROJECT_DEPLOYMENTS --database <DATABASE>
```

---

## Reference Files

Load on demand — only read files relevant to the current step.

**Workflows:** `references/workflows/` — `net-new-patterns.md`, `extension-patterns.md`,
`migration-patterns.md`, `semantic-view-patterns.md`, `cortex-agent-patterns.md`,
`task-orchestration-patterns.md`, `conventions.md`

**Templates:** `references/templates/` — `example-agent-spec.yml`, `example-dbt-project.yml`,
`example-profiles.yml`, `example-document-full-extracts.yml`,
`example-document-question-extracts.yml`, `example-snowflake-yml.yml`

**Scripts:** `scripts/` — `example_sysadmin_objects.sql`, `example_read_stage_file.sql`,
`example_create_cortex_agent.sql`, `example_create_document_search_sevice.sql`,
`example_deploy_cortex_tasks.sql`, `example_document_full_extracts.sql`,
`example_document_question_extracts.py`, `example_semantic_view.sql`,
`example_attach_freshness_dmf.sql`
