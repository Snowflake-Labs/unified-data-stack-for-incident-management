
    
    

with all_values as (

    select
        priority as value_field,
        count(*) as n_records

    from incident_management.gold_zone.closed_incidents
    group by priority

)

select *
from all_values
where value_field not in (
    'low','medium','high','critical'
)


