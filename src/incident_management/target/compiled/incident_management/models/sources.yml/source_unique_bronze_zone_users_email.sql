
    
    

select
    email as unique_field,
    count(*) as n_records

from v1_incident_management.bronze_zone.users
where email is not null
group by email
having count(*) > 1


