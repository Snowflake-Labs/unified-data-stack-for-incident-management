{% macro clean_stale_documents(stage_name: string) -%}

remove {{ stage_name | replace("'", "") }} pattern='.*';

{% endmacro %}
