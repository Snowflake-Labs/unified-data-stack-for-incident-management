{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['filename'],
    merge_exclude_columns=['created_at'],
    description='Flattened question extracts from documents with quarterly review metrics'
  )
}}


with document_question_extracts as (
  select 
  split(relative_path, '/')[1] as filename,
  QUESTION_EXTRACTS_JSON:response as response
  from {{ ref('document_question_extracts') }} 
  where is_null_value(question_extracts_json:error)
)
select
dq.filename,
lf.key as metric,
lf.value::string as value,
current_timestamp() as created_at,
from document_question_extracts dq,
lateral flatten(input => response) lf

