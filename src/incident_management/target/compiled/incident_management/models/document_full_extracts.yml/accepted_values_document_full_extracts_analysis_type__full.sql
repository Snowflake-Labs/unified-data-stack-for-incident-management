
    
    

with all_values as (

    select
        analysis_type as value_field,
        count(*) as n_records

    from incident_management.bronze_zone.document_full_extracts
    group by analysis_type

)

select *
from all_values
where value_field not in (
    'full'
)


