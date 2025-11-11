
    
    

select
    incident_number as unique_field,
    count(*) as n_records

from v1_incident_management.gold_zone.closed_incidents
where incident_number is not null
group by incident_number
having count(*) > 1


