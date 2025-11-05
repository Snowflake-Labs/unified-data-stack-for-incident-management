{% macro get_response_format(file_path) %}
  {% set json_data = load_file(file_path) | fromjson %}
  {{ return(json_data) }}
{% endmacro %}

