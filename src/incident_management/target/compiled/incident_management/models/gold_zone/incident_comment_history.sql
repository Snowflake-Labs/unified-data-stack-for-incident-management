

select 
    slack_message_id as id,
    i.incident_number,
    i.reportee_id as author_id,
    i.last_comment as content,
    current_timestamp() as created_at
from incident_management.gold_zone.incidents i

