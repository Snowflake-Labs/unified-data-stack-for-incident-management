

select 
    sm.MEMBERIDS[0] as id,
    sm.memberemails[0] as email,
    split(sm.memberemails[0], '@')[0] as first_name,
    split(sm.memberemails[0], '@')[1] as last_name,
    'reporter' as role,
    '' as department,
    '' as team,
    true as is_active,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from incident_management.bronze_zone.slack_members sm