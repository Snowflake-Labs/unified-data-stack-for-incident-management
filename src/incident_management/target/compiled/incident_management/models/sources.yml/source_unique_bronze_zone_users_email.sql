
    
    

select
    email as unique_field,
    count(*) as n_records

from incident_management.bronze_zone.users
where email is not null
group by email
having count(*) > 1


