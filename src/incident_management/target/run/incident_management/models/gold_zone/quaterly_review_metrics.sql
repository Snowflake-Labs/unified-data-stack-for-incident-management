
  
    

        create or replace transient table incident_management.gold_zone.quaterly_review_metrics
         as
        (


with document_question_extracts as (
  select 
  split(relative_path, '/')[1] as filename,
  QUESTION_EXTRACTS_JSON:response as response
  from incident_management.silver_zone.document_question_extracts 
  where is_null_value(question_extracts_json:error)
)
select
dq.filename,
lf.key as metric,
lf.value::string as value,
current_timestamp() as created_at,
from document_question_extracts dq,
lateral flatten(input => response) lf
        );
      
  