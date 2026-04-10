# dbt-cortex-pipeline -- Battle Card

## What It Does

Builds end-to-end dbt pipelines on Snowflake that combine data models with Cortex AI services (Semantic Views, Cortex Search, Cortex Agents) in a single deployable dbt project.

## Three Entry Scenarios

| Scenario | Starting Point | Key Action |
|---|---|---|
| **Net New** | No existing dbt project | Scaffold full medallion architecture from scratch |
| **Extension** | Existing dbt project in a local repo | Add Cortex services on top of existing models |
| **DT Migration** | Existing Dynamic Table pipeline | Convert DTs to `materialized='dynamic_table'` dbt models, then add Cortex |

## Core Capabilities

### Data Modeling (Medallion Architecture)
- **Bronze**: Pass-through models over source tables; stream-based qualifying views for staged documents
- **Silver**: Incremental models with joins, dedup, AI enrichment (`AI_EXTRACT` for structured extraction from documents)
- **Gold**: Business-ready fact/dimension tables; `AI_PARSE_DOCUMENT` + `SPLIT_TEXT_MARKDOWN_HEADER` for document chunking

### Cortex AI Services
| Service | Purpose | Tooling |
|---|---|---|
| **Semantic View** | Text-to-SQL via Cortex Analyst | `dbt_semantic_view` package; TABLES, RELATIONSHIPS, FACTS, DIMENSIONS, METRICS clauses |
| **Cortex Search** | Vector search over unstructured text/documents | dbt macro (`create_cortex_search_service`) deploying a search service over chunk columns |
| **Cortex Agent** | Conversational AI combining text-to-sql + search | YAML spec + dbt macro (`create_cortex_agent`) with idempotent create-or-replace |
| **Snowflake Intelligence** | Optional SI registration for the agent | Toggle-controlled via `dbt_project.yml` vars |

### Infrastructure & Orchestration
- **Database/schema provisioning**: Automated via `sysadmin_objects.sql` (BRONZE_ZONE, SILVER_ZONE, GOLD_ZONE, DBT_PROJECT_DEPLOYMENTS)
- **Task DAGs**: Up to 3 independent Snowflake task graphs:
  1. CRON-scheduled model refresh (`tag:daily`)
  2. Stream-triggered document processing (`SYSTEM$STREAM_HAS_DATA`)
  3. Manual Cortex services deployment (semantic view + search + agent)
- **Deployment**: `snow dbt deploy` as a Snowflake-native dbt project object

### Optional Features
| Feature | Toggle | What It Adds |
|---|---|---|
| **Iceberg tables** | `iceberg_enabled: true` | Gold-layer models as Snowflake-managed Iceberg via `catalogs.yml` + `+catalog` config (requires dbt-snowflake 1.10+) |
| **Data freshness DMFs** | `dmf_freshness_tables` var | `attach_freshness_dmf` macro as post-hook + `data_freshness_checks` view model + semantic view metric |
| **Snowflake Intelligence** | `toggle_si_agent_deployment: true` | Registers the Cortex Agent with SI |

## Pre-Scenario Gates (Always Required)

1. **External Access Integration** -- egress to `github.com`, `codeload.github.com`, `hub.getdbt.com`
2. **Snowflake Intelligence toggle** -- yes/no + SI object name
3. **Iceberg toggle** -- yes/no + external volume + catalog integration + dbt-snowflake version check

## Key Guardrails & Gotchas

- **Semantic View syntax**: `table_alias.semantic_name AS physical_column_expression` (semantic name on LEFT, physical column on RIGHT) -- getting this reversed breaks Cortex Analyst
- **Vars audit**: Every `var()` / `dbt.config.get()` in any script must have a default in `dbt_project.yml`
- **`generate_schema_name` macro**: Must output clean schema names (no target prefix)
- **`READ_STAGE_FILE` UDF**: Must exist in `DBT_PROJECT_DEPLOYMENTS` before agent deployment
- **Package pinning**: `dbt_semantic_view` version must be looked up and pinned, never left unpinned
- **Document AI placement**: `AI_EXTRACT` in silver only; `AI_PARSE_DOCUMENT` + chunking in gold only
- **Deployment skill dependency**: Must load `dbt-projects-on-snowflake` skill before any `snow dbt` command

## User Checkpoints (Approval Gates)

1. Semantic View structure (TABLES, RELATIONSHIPS, FACTS, DIMENSIONS)
2. `snowflake.yml` configuration
3. Pre-deploy summary (models, macros, Cortex services)
4. Post-deploy confirmation
5. Stream creation permission (if document stage data)

## Bundled Assets

| Category | Files |
|---|---|
| **Templates** (7) | `example-agent-spec.yml`, `example-catalogs-yml.yml`, `example-dbt-project.yml`, `example-profiles.yml`, `example-snowflake-yml.yml`, `example-document-full-extracts.yml`, `example-document-question-extracts.yml` |
| **Scripts** (9) | `example_sysadmin_objects.sql`, `example_read_stage_file.sql`, `example_create_cortex_agent.sql`, `example_create_document_search_sevice.sql`, `example_deploy_cortex_tasks.sql`, `example_document_full_extracts.sql`, `example_document_question_extracts.py`, `example_semantic_view.sql`, `example_attach_freshness_dmf.sql` |
| **Workflows** (7) | `net-new-patterns.md`, `extension-patterns.md`, `migration-patterns.md`, `semantic-view-patterns.md`, `cortex-agent-patterns.md`, `task-orchestration-patterns.md`, `conventions.md` |

## Relationship to `dbt-projects-on-snowflake` (Bundled Skill)

### What the Bundled Skill Does

`dbt-projects-on-snowflake` is an **operations skill** for managing dbt projects that are already deployed as Snowflake-native objects. It handles:

| Capability | Commands |
|---|---|
| **Deploy** | `snow dbt deploy` -- upload a built dbt project into Snowflake |
| **Execute** | `snow dbt execute`, `EXECUTE DBT PROJECT` -- run/test/build/seed/show models |
| **Manage** | `SHOW/DESCRIBE/ALTER/DROP DBT PROJECT`, add versions, rename |
| **Schedule** | `CREATE TASK ... EXECUTE DBT PROJECT` with suspend/resume lifecycle |
| **Monitor** | Execution history, logs, artifacts, debug failures |
| **Migrate** | Convert local dbt projects (resolve `env_var()`, profiles.yml) for Snowflake deployment |

It knows the **correct CLI and SQL syntax** for Snowflake-native dbt (e.g., `ARGS='docs generate'` not JSON arrays, no serverless tasks, schema filtering for history queries).

### What This Skill Adds On Top

`dbt-cortex-pipeline` is a **design + build skill** that creates the dbt project content itself -- then hands off to the bundled skill for deployment. It extends the bundled skill in these areas:

| Area | Bundled Skill | This Skill |
|---|---|---|
| **Scope** | Deploys/runs any dbt project | Designs and generates a dbt project with Cortex AI services |
| **Project creation** | Assumes project already exists | Scaffolds the entire project from scratch (models, macros, configs, YAML specs) |
| **Data modeling** | No opinion on model structure | Prescribes medallion architecture (bronze/silver/gold) with layer-specific materialization rules |
| **Cortex AI** | Not covered | Generates Semantic Views, Cortex Search macros, Cortex Agent specs + deployment macros |
| **Document processing** | Not covered | Full pipeline: stream triggers, `AI_EXTRACT` (silver), `AI_PARSE_DOCUMENT` + chunking (gold) |
| **Iceberg** | Not covered | Optional gold-layer Iceberg tables via `catalogs.yml` + `+catalog` config |
| **Data freshness** | Not covered | DMF-based freshness monitoring with `attach_freshness_dmf` macro + semantic view metric |
| **Task orchestration** | Single-task scheduling | Multi-DAG task graphs (CRON refresh, stream-triggered docs, manual Cortex deploy) |
| **Snowflake Intelligence** | Not covered | Optional agent registration with SI |
| **Dynamic Table migration** | Not covered | Discovery, lineage mapping, lift-and-shift to `materialized='dynamic_table'` |

### How They Work Together

```
dbt-cortex-pipeline                    dbt-projects-on-snowflake
(design + build)                       (deploy + operate)

  Gather requirements                       |
       |                                    |
  Scaffold project                          |
       |                                    |
  Generate models, macros,                  |
  semantic views, agent specs               |
       |                                    |
  Generate snowflake.yml                    |
       |                                    |
       +------ HANDOFF ----->  snow dbt deploy
                               snow dbt execute
                               EXECUTE DBT PROJECT (via tasks)
                               Monitor / debug / manage
```

The handoff happens at the **Final Step** of every scenario. At that point, this skill **requires** the bundled skill to be loaded for all `snow dbt` commands.

### When to Use Which

| User Request | Skill |
|---|---|
| "Build me a dbt project with a Cortex Agent" | `dbt-cortex-pipeline` |
| "Add a semantic view and agent to my existing dbt project" | `dbt-cortex-pipeline` (Extension scenario) |
| "Convert my Dynamic Tables to dbt with Cortex" | `dbt-cortex-pipeline` (Migration scenario) |
| "Deploy my dbt project to Snowflake" | `dbt-projects-on-snowflake` |
| "Run my deployed dbt project" | `dbt-projects-on-snowflake` |
| "Schedule my deployed project with a Snowflake task" | `dbt-projects-on-snowflake` |
| "Why did my deployed dbt project fail?" | `dbt-projects-on-snowflake` |
| "Migrate my local dbt project for Snowflake deployment" | `dbt-projects-on-snowflake` |

---

## What This Skill Does NOT Cover

- Standalone Cortex Agent creation without dbt (use `cortex-agent` skill)
- Standalone semantic view SQL without dbt (use `semantic-view` skill)
- Debugging existing dbt models
- Deploying an already-built dbt project (use `dbt-projects-on-snowflake` skill)
- Single AI function SQL queries without a pipeline (use `cortex-ai-functions` skill)
