
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from incident_management.gold_zone.closed_incidents
    group by status

)

select *
from all_values
where value_field not in (
    'closed','resolved'
)


