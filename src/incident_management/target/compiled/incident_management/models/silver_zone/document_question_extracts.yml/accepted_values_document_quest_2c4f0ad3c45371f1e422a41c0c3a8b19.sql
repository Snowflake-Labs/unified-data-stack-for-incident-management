
    
    

with all_values as (

    select
        analysis_type as value_field,
        count(*) as n_records

    from v1_incident_management.silver_zone.document_question_extracts
    group by analysis_type

)

select *
from all_values
where value_field not in (
    'question'
)


