{{ config(materialized='semantic_view') }}

TABLES(
  {{ ref('document_full_extracts') }}
    PRIMARY KEY (o_orderkey)
    WITH SYNONYMS ('sales orders')
    COMMENT = 'All orders table for the sales domain'
)