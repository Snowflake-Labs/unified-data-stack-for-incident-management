{% macro clean_stale_documents() -%}

{% set docs_stage_path = var("docs_stage_path") | replace("'", "") %}

remove {{ docs_stage_path }}/*;  

{% endmacro %}