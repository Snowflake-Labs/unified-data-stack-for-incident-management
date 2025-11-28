{{
  config(
    materialized='incremental'
    ,incremental_strategy='merge'
    ,unique_key=['filename']
    ,merge_exclude_columns=['created_at']
    ,description='Flattened question extracts from documents with quarterly review metrics'
    ,tags=['document_processing']
  )
}}


with document_question_extracts as (
  select 
  split(relative_path, '/')[1] as filename,
  QUESTION_EXTRACTS_JSON:response as response
  from {{ ref('document_question_extracts') }} 
  where 
  {% if is_incremental() %}
    lower(trim(filename)) not in ( select distinct lower(trim(filename)) from {{ this }} )
    and to_timestamp_ntz(last_modified) > ( select max(to_timestamp_ntz(created_at)) from {{ this }} )
    and is_null_value(question_extracts_json:error)
  {% endif %}
  
)
select
dq.filename,
lf.key as metric,
lf.value::string as value,
current_timestamp() as created_at,
from document_question_extracts dq,
lateral flatten(input => response) lf

