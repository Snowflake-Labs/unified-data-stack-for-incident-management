# Getting Started: Building Skills for Cortex Code

## What is a Skill?

A skill is a markdown file that teaches Cortex Code how to complete a specific task. Skills provide structured workflows, tool references, decision logic, and user checkpoints -- turning repeatable processes into reusable, shareable instructions that any Cortex Code user can invoke.

Skills are invoked with the `$` prefix:

```
$my-skill do something specific
```

---

## Skill Locations & Priority

Skills are loaded in priority order (first match wins):


| Priority | Location | Path                          | Scope               |
| -------- | -------- | ----------------------------- | ------------------- |
| 1        | Project  | `.cortex/skills/`             | This repo only      |
| 2        | Global   | `~/.snowflake/cortex/skills/` | All projects        |
| 3        | Remote   | Cached from GitHub repos      | Shared across teams |
| 4        | Bundled  | Shipped with Cortex Code      | Always available    |


---

## Minimal Skill in 5 Minutes

### 1. Create the directory

```bash
# Project-local skill (only this repo)
mkdir -p .cortex/skills/my-skill

# Or global skill (all projects)
mkdir -p ~/.snowflake/cortex/skills/my-skill
```

### 2. Create `SKILL.md`

Every skill needs exactly one `SKILL.md` file with YAML frontmatter and a markdown body:

```markdown
---
name: my-skill
description: "Generates a data quality report for a Snowflake table. Use when: checking data quality, profiling columns, validating table health. Triggers: data quality, profile table, column stats."
---

# Data Quality Report

## Workflow

### Step 1: Describe your first step in workflow
....
### Step n: Describe your last step in workflow
```

**Good description:**

```yaml
description: "Create, edit, and validate dbt models on Snowflake. Use when: building dbt pipelines, fixing model errors, adding tests. Triggers: dbt model, dbt test, dbt build."
```

**Bad description:**

```yaml
description: "A skill for working with data"  # Too vague, no triggers
```

### Body Sections


| Section              | Required | Purpose                                                     |
| -------------------- | -------- | ----------------------------------------------------------- |
| `## Workflow`        | Yes      | Step-by-step instructions with numbered steps               |
| `## Stopping Points` | Yes      | Where to pause for user input -- prevents runaway execution |
| `## Output`          | Yes      | What the skill produces                                     |
| `## Tools`           | No       | Script or CLI tool documentation                            |
| `## Prerequisites`   | No       | What must be in place before starting                       |
| `## Troubleshooting` | No       | Common issues and fixes                                     |


---

## Complexity Levels

### Simple: Single File (most skills)

```
my-skill/
└── SKILL.md
```

Use when the workflow is linear, under ~500 lines, and has a single purpose.

### Medium: With References

```
my-skill/
├── SKILL.md
└── references/
    ├── aws-setup.md       # Loaded when user picks AWS
    └── schema-guide.md    # Loaded on demand
```

Use when you need detailed reference material that shouldn't bloat the main file.

### Complex: With Sub-Skills

```
my-skill/
├── SKILL.md              # Entry point with intent routing
├── create/
│   └── SKILL.md          # Full workflow for "create" intent
├── debug/
│   └── SKILL.md          # Full workflow for "debug" intent
└── scripts/
    ├── validate.py
    └── deploy.py
```

Use when different user intents require completely different workflows.

**Rule of thumb:** Start simple. Only split when your single file exceeds ~500 lines or has 3+ distinct workflow branches.

---

## Adding Scripts

Skills can include Python scripts for complex operations (API calls, data processing, validation).

### Directory structure

```
my-skill/
├── SKILL.md
├── pyproject.toml         # Dependencies
└── scripts/
    └── run_check.py
```

### Documenting scripts in SKILL.md

```markdown
## Tools

### Script: run_check.py

**Description**: Validates table schema against expected definitions.

**Usage:**
```bash
uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/run_check.py \
  --table <TABLE_NAME> --output <output.json>
```

**Arguments:**

- `--table`: Target table (required)
- `--output`: Output file path (default: stdout)

### Decision Routing

```markdown
### Step 2: Choose Approach

**Ask** user which approach they prefer:
1. Full rebuild -- drops and recreates
2. Incremental -- applies changes only

**If Option 1:** Load `rebuild/SKILL.md`
**If Option 2:** Load `incremental/SKILL.md`
```

### Validation Checkpoints

```markdown
### Step 4: Validate

**Checklist:**
- [ ] Output file exists and is non-empty
- [ ] Row counts match expected range
- [ ] No error messages in logs

**If validation fails:** Return to Step 3 (max 3 retries).
**If validation passes:** Proceed to Step 5.
```

---

## Bundled Skills for Reference

Cortex Code ships with **38 bundled skills** covering Snowflake, data engineering, security, ML, and more. These serve as both working tools and examples of well-structured skills. Use `$skill-development` to get help building your own.

### Data & Analytics


| Skill            | What It Does                                               |
| ---------------- | ---------------------------------------------------------- |
| `sql-author`     | Write, run, and debug SQL against Snowflake tables         |
| `analyzing-data` | Query data warehouse and answer business questions         |
| `dynamic-tables` | Create, optimize, monitor, and troubleshoot Dynamic Tables |
| `data-quality`   | Data quality monitoring with Data Metric Functions (DMFs)  |
| `lineage`        | Analyze data lineage and dependencies; impact analysis     |
| `dashboard`      | Create interactive dashboards with charts and tables       |


### Cortex AI


| Skill                 | What It Does                                                                              |
| --------------------- | ----------------------------------------------------------------------------------------- |
| `cortex-agent`        | Create, edit, debug, and manage Cortex Agents                                             |
| `semantic-view`       | Create, debug, and optimize Semantic Views for Cortex Analyst                             |
| `cortex-ai-functions` | Use Cortex AI functions (classify, extract, summarize, translate, embed, parse documents) |
| `machine-learning`    | End-to-end ML workflows: training, deployment, model registry, feature store              |


### Data Engineering


| Skill                       | What It Does                                                                 |
| --------------------------- | ---------------------------------------------------------------------------- |
| `dbt-cortex-pipeline`       | Build dbt pipelines with Cortex AI services (Semantic Views, Search, Agents) |
| `dbt-projects-on-snowflake` | Manage dbt projects deployed as Snowflake native objects via `snow dbt`      |
| `snowpark-python`           | Write Snowpark Python pipelines, UDFs, stored procedures                     |
| `iceberg`                   | Iceberg tables, catalog integrations, external volumes                       |
| `openflow`                  | NiFi-based data replication and transformation                               |
| `snowflake-notebooks`       | Create and edit Snowflake workspace notebooks                                |


### Security & Governance


| Skill                       | What It Does                                                          |
| --------------------------- | --------------------------------------------------------------------- |
| `data-governance`           | Masking policies, row access, classification, governance maturity     |
| `security-investigation`    | Login anomalies, threat detection, brute force, exfiltration analysis |
| `trust-center`              | Security findings, scanner analysis, CIS benchmarks                   |
| `network-security`          | Network policy recommendations, evaluation, migration                 |
| `key-and-secret-management` | Tri-Secret Secure, customer-managed keys, key rotation                |


### Platform & Infrastructure


| Skill                       | What It Does                                                  |
| --------------------------- | ------------------------------------------------------------- |
| `developing-with-streamlit` | Build and deploy Streamlit applications on Snowflake          |
| `deploy-to-spcs`            | Deploy containerized apps to Snowpark Container Services      |
| `native-app-provider`       | Build and publish Snowflake Native Apps                       |
| `native-app-consumer`       | Install and configure Native Apps from listings               |
| `warehouse`                 | Warehouse sizing, Gen2 migration, cost and performance        |
| `cost-intelligence`         | Spending analysis, budgets, resource monitors, cost anomalies |
| `organization-management`   | Multi-account org management, org-wide metrics                |
| `snowflake-postgres`        | Snowflake Postgres instances: create, manage, diagnose        |


### Sharing & Collaboration


| Skill                              | What It Does                                                     |
| ---------------------------------- | ---------------------------------------------------------------- |
| `declarative-sharing`              | Share data products across accounts with versioning              |
| `data-cleanrooms`                  | Snowflake Data Clean Rooms for secure collaboration              |
| `integrations`                     | Create and manage Snowflake integrations (API, catalog, storage) |
| `internal-marketplace-org-listing` | Publish data products to Internal Marketplace                    |


### Development & Skill Building


| Skill               | What It Does                                                        |
| ------------------- | ------------------------------------------------------------------- |
| `skill-development` | Create, audit, and summarize skills (use this to build your own)    |
| `cortex-code-guide` | Complete reference for Cortex Code CLI, commands, and configuration |
| `code-validation`   | Validate SQL, Python, Java, Scala for syntax and correctness        |
| `build-react-app`   | Build React/Next.js apps with Snowflake data                        |
| `snowpark-connect`  | Migrate PySpark workloads to Snowpark Connect                       |


---

## Managing Skills

Use the `/skill` slash command inside Cortex Code to open the interactive skill manager:

```
/skill          # View, create, delete, and sync skills
```

From the manager you can:

- View all skills by location (project, global, remote, bundled)
- Create new skills (press `a`)
- Sync project skills to global
- Delete skills
- View skill details and detect conflicts

### Remote Skills

Share skills across a team via Git repositories. Configure in `~/.snowflake/cortex/skills.json`:

```json
{
  "remote": [
    {
      "source": "https://github.com/your-org/cortex-skills",
      "ref": "main",
      "skills": [{ "name": "your-team-skill" }]
    }
  ]
}
```

where, 

source is the main git repo home

ref is the name of the branch

[skill.name](http://skill.name) is the exact name of the directory under your git repo which hosts the [SKILL.md](http://SKILL.md) and other reference files (if any).



