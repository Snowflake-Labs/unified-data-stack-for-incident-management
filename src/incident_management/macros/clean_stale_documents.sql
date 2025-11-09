{% macro clean_stale_documents(stage_name) -%}

{% set sql %}
    remove {{ stage_name | replace("'", "") }} pattern='.*';
{% endset %}

{% do run_query(sql) %}

{% endmacro %}
