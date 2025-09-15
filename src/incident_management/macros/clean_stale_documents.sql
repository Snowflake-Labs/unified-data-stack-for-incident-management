{% macro clean_stale_documents() -%}

{% set docs_stage_path = var("docs_stage_path") %}

remove {{ docs_stage_path }}/*;  

{% endmacro %}