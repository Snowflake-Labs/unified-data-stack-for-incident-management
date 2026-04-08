-- =============================================================================
-- Semantic View Template for dbt + Cortex AI Pipeline
-- =============================================================================
-- Use this as a reference when building a semantic view model.
-- Replace all <placeholder> values with actual model names and columns
-- from the dbt project's gold layer.
--
-- File: models/semantic_views/<view_name>.sql
-- Requires: Snowflake-Labs/dbt_semantic_view package
-- =============================================================================


-- ---------------------------------------------------------------------------
-- TABLES CLAUSE
-- ---------------------------------------------------------------------------
-- Declare gold-layer models using {{ ref() }} to maintain dbt lineage.
-- Each table can have a PRIMARY KEY and COMMENT.

{{ config(materialized='semantic_view') }}

TABLES(
  <table_alias_1> as {{ ref('<gold_model_1>') }}
    PRIMARY KEY(<primary_key_column>)
    COMMENT = '<description of what this table contains>'

  , <table_alias_2> as {{ ref('<gold_model_2>') }}
    COMMENT = '<description of what this table contains>'

  , <table_alias_3> as {{ ref('<gold_model_3>') }}
    COMMENT = '<description of what this table contains>'
)


-- ---------------------------------------------------------------------------
-- RELATIONSHIPS CLAUSE
-- ---------------------------------------------------------------------------
-- Define foreign key relationships so Cortex Analyst knows how to join tables.
-- Naming convention: <child_alias>_to_<parent_alias>

RELATIONSHIPS (
    <child_alias>_to_<parent_alias> AS
      <child_alias> (<foreign_key_col>) REFERENCES <parent_alias> (<primary_key_col>)
    , <another_child>_to_<parent_alias> AS
      <another_child> (<foreign_key_col>) REFERENCES <parent_alias> (<primary_key_col>)
)


-- ---------------------------------------------------------------------------
-- FACTS CLAUSE
-- ---------------------------------------------------------------------------
-- Numeric columns used for aggregation (amounts, durations, counts, scores).
-- Include temporal aggregation fields (year, quarter, month) when used
-- for time-series grouping. Always add COMMENT with units.

FACTS (
    <table_alias>.<numeric_column> AS <fact_name>
      COMMENT = '<description with units, e.g. "Total amount in USD">'
    , <table_alias>.<another_numeric_column> AS <fact_name>
      COMMENT = '<description with units>'
    , <table_alias>.<year_column> AS <year_fact>
      COMMENT = '<e.g. "Year when the transaction occurred">'
    , <table_alias>.<quarter_column> AS <quarter_fact>
      COMMENT = '<e.g. "Quarter when the transaction occurred">'
)


-- ---------------------------------------------------------------------------
-- DIMENSIONS CLAUSE
-- ---------------------------------------------------------------------------
-- Columns used for filtering and grouping. Use SYNONYMS for informal terms,
-- abbreviations, and domain jargon. Use COMMENT to list valid values for
-- fixed-value columns.

DIMENSIONS (
   -- Identifier dimension
   <table_alias>.<id_column> AS <id_column>
     WITH SYNONYMS = ('<informal name>', '<abbreviation>')
     COMMENT = '<description of the identifier>'

   -- Category dimension with valid values
   , <table_alias>.<category_column> AS <category_column>
     WITH SYNONYMS = ('<alternate term 1>', '<alternate term 2>',
                      '<domain jargon term>')
     COMMENT = '<description>. Valid values: value_a, value_b, value_c'

   -- Status dimension with valid values
   , <table_alias>.<status_column> AS <status_column>
     WITH SYNONYMS = ('<alternate term>', '<abbreviation>')
     COMMENT = '<description>. Valid values: active, inactive, pending'

   -- Temporal dimension
   , <table_alias>.<timestamp_column> AS <timestamp_column>
     WITH SYNONYMS = ('<informal date name>', '<alternate date term>')
     COMMENT = '<e.g. "Creation timestamp">'

   -- People/Entity dimension
   , <table_alias>.<person_id_column> AS <person_id_column>
     WITH SYNONYMS = ('<role name>', '<informal reference>')
     COMMENT = '<e.g. "Assigned user identifier">'

   -- Multi-table dimension: add SYNONYMS only on the primary table
   , <primary_table>.<column> AS <column>
     WITH SYNONYMS = ('<synonym 1>', '<synonym 2>')
     COMMENT = '<description>'
   , <secondary_table>.<column> AS <column>
     COMMENT = '<description>'
)


-- =============================================================================
-- COMPLETE EXAMPLE: Orders / Customers / Returns
-- =============================================================================
-- A filled-in semantic view combining multiple gold zone tables.
-- File: models/semantic_views/my_analytics.sql

{{ config(materialized='semantic_view') }}

TABLES(
  orders as {{ ref('orders') }}
    PRIMARY KEY(order_id)
    COMMENT = 'Customer orders with status and amounts'

  , customers as {{ ref('customers') }}
    PRIMARY KEY(customer_id)
    COMMENT = 'Customer directory with plan tiers'

  , returns as {{ ref('returns') }}
    COMMENT = 'Product returns with reason codes'
)

RELATIONSHIPS (
    orders_to_customers AS
      orders (customer_id) REFERENCES customers (customer_id)
    , returns_to_orders AS
      returns (order_id) REFERENCES orders (order_id)
)

FACTS (
    orders.total_amount AS total_amount
      COMMENT = 'Order total in USD'
    , orders.item_count AS item_count
      COMMENT = 'Number of items in order'
    , returns.refund_amount AS refund_amount
      COMMENT = 'Refund amount in USD'
)

DIMENSIONS (
   orders.order_id AS order_id
     WITH SYNONYMS = ('order', 'order number', 'order #')
     COMMENT = 'Unique order identifier'
   , orders.status AS status
     WITH SYNONYMS = ('order status', 'order state')
     COMMENT = 'Order status. Valid values: pending, shipped, delivered, cancelled'
   , orders.created_at AS created_at
     WITH SYNONYMS = ('order date', 'purchase date', 'ordered at')
     COMMENT = 'Order creation timestamp'

   , customers.customer_id AS customer_id
     WITH SYNONYMS = ('customer', 'buyer')
     COMMENT = 'Customer identifier'
   , customers.name AS name
     WITH SYNONYMS = ('customer name', 'buyer name')
     COMMENT = 'Customer full name'
   , customers.plan_tier AS plan_tier
     WITH SYNONYMS = ('plan', 'subscription tier', 'account type')
     COMMENT = 'Subscription plan. Valid values: free, starter, professional, enterprise'

   , returns.reason AS reason
     WITH SYNONYMS = ('return reason', 'refund reason')
     COMMENT = 'Return reason code'
)
