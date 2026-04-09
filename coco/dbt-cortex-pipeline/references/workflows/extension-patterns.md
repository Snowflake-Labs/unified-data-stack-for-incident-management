# Extension Patterns

## Project Exploration Workflow

### Step 1: Use fdbt for Structure Discovery

```
fdbt info                     # Project name, version, profile, paths
fdbt list                     # All models with materializations
fdbt lineage <model> -u       # Upstream deps for a specific model
fdbt tests coverage           # Test coverage overview
```

### Step 2: Read Key Configuration Files

1. `dbt_project.yml` — schema layout, materializations, vars, tags
2. `packages.yml` — existing packages
3. `macros/` — custom schema macros, materializations
4. `models/` top-level structure — layer naming convention

### Step 3: Identify the Top Data Layer

| Convention | Directory |
|-----------|-----------|
| Medallion | `gold_zone/`, `gold/` |
| dbt best practice | `marts/` |
| Presentation | `presentation/`, `analytics/` |
| Output | `output/`, `reporting/` |

Read each top-layer model's SQL to understand columns, joins, and
business logic (for FACTS/DIMENSIONS/RELATIONSHIPS inference).

### Step 4: Detect Text Chunk Models

Scan all models for chunk-like columns: `chunk`, `text_chunk`, `content_chunk`,
`extract`, `body`, `text_content`, `document_text`, `page_text`,
`section_text`, `embedding_text`. Models with these are Cortex Search candidates.

## Adding Prerequisites

### packages.yml

Add `Snowflake-Labs/dbt_semantic_view` if missing (pinned to latest).

### dbt_project.yml

Add the `semantic_views` section. Match existing indentation.
See `../templates/example-dbt-project.yml`.

### generate_schema_name Macro

Check if the project already has this macro producing clean schema names.
Only add/update if the user wants `semantic_views` as the exact schema
name. See `net-new-patterns.md` for the macro.

## Preserving Existing Conventions

| Aspect | Match |
|--------|-------|
| **Naming** | Follow existing prefix pattern (`stg_`, `int_`, `fct_`, `dim_`) |
| **Materialization** | Keep existing gold zone strategy (`view`/`table`) |
| **Tags** | Use existing tag vocabulary |
| **Schema files** | Follow existing `.yml` per-directory or per-model pattern |
| **Tests/Docs** | Match existing density and style |

## Inferring Semantic View Content

### From Column Names to FACTS

Numeric columns that represent measures:

| Column Name Pattern | Semantic View Role |
|--------------------|-------------------|
| `*_amount`, `*_total`, `*_sum` | FACT |
| `*_count`, `*_qty`, `*_quantity` | FACT |
| `*_hours`, `*_minutes`, `*_duration` | FACT |
| `*_rate`, `*_ratio`, `*_percentage` | FACT |
| `*_score`, `*_rank` | FACT |
| `revenue`, `cost`, `price`, `profit` | FACT |

### From Column Names to DIMENSIONS

Categorical, identifier, and temporal columns:

| Column Name Pattern | Semantic View Role |
|--------------------|-------------------|
| `*_id`, `*_key`, `*_number` | DIMENSION |
| `*_name`, `*_type`, `*_category` | DIMENSION + SYNONYMS |
| `*_status`, `*_state` | DIMENSION + SYNONYMS |
| `*_date`, `*_at`, `*_timestamp` | DIMENSION + temporal SYNONYMS |
| `*_flag`, `is_*`, `has_*` | DIMENSION |

### From Joins to RELATIONSHIPS

When a model joins table A to table B on `A.fk = B.pk`, create:

```sql
RELATIONSHIPS (
  a_to_b AS
    table_a (fk_column) REFERENCES table_b (pk_column)
)
```

If the model uses `LEFT JOIN`, the relationship is `many_to_one`.
