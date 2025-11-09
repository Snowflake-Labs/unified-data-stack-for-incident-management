{% macro create_document_search_service(service_name, search_wh, search_column, target_lag) %}

{% set sql %}
    CREATE OR REPLACE CORTEX SEARCH SERVICE {{ target.database }}.BRONZE_ZONE.{{ service_name }}
      ON {{ search_column }}
      ATTRIBUTES RELATIVE_PATH, EXTENSION
      WAREHOUSE = {{ search_wh }}
      TARGET_LAG = '{{ target_lag }}'
      EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
      SELECT
        CHUNK,
        RELATIVE_PATH,
        EXTENSION
      FROM {{ target.database }}.BRONZE_ZONE.DOCUMENT_FULL_EXTRACTS
    );
{% endset %}

{% do run_query(sql) %}

{% endmacro %}
