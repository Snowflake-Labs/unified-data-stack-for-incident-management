# Semantic View Patterns

Uses `{{ config(materialized='semantic_view') }}` with up to five
clauses: TABLES, RELATIONSHIPS, FACTS, METRICS, DIMENSIONS.

See `scripts/example_semantic_view.sql` for the full template.

## Required Package

`Snowflake-Labs/dbt_semantic_view`

## Key Rules

- Use `{{ ref() }}` for all table references to maintain dbt lineage
- Use the alias (left of `as`) consistently across all clauses
- Naming convention for relationships: `<child>_to_<parent>`
- When multiple tables expose the same dimension, add SYNONYMS only on
  the primary/canonical table to avoid ambiguity
- **CRITICAL — FACTS and DIMENSIONS column syntax:** The correct format is
  `table_alias.semantic_name AS physical_column_expression`, **not** the
  reverse. The semantic name (how Cortex Analyst exposes the column) goes
  on the left, and the physical column or expression goes on the right.
  Example: `orders.order_total AS total_amount_usd` means the semantic
  name is `order_total` and the underlying column is `total_amount_usd`.
  Getting this backwards causes Cortex Analyst to generate incorrect SQL.

## METRICS Clause

The optional `METRICS` clause defines computed expressions over table
columns. Use METRICS for derived values that combine columns or apply
string/numeric transformations — as opposed to FACTS, which expose raw
numeric columns directly.

```sql
METRICS (
    metric_name AS <expression>
      WITH SYNONYMS = ('synonym1', 'synonym2')
)
```

### When to Use METRICS vs FACTS

| Use Case | Clause |
|----------|--------|
| Raw numeric column (amount, count, hours) | FACTS |
| Computed expression combining columns | METRICS |
| Human-readable summary from multiple fields | METRICS |
| Aggregation-ready measure | FACTS |

### Data Freshness Metric Example

Always include the `data_freshness_checks` model in the semantic view
`TABLES()` clause and add a metric that produces a human-readable freshness
summary:

```sql
METRICS (
    data_freshness_summary AS
      data_freshness_checks.table_name || ' was last updated '
      || data_freshness_checks.value || ' seconds ago'
      WITH SYNONYMS = ('data freshness', 'last updated', 'data staleness')
)
```

## Tips for Effective Text2SQL

1. **Synonyms** — capture informal terms, abbreviations, and domain jargon
2. **Comments with valid values** — list fixed value sets so Cortex Analyst
   generates correct filters (e.g. `Valid values: critical, high, medium, low`)
3. **Structured + unstructured** — a semantic view can include both regular
   tables and `AI_EXTRACT` output tables for cross-domain questions
