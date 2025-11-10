

select 
    slack_message_id as id,
    i.incident_number,
    i.reportee_id as author_id,
    i.last_comment as content,
    current_timestamp() as created_at
from incident_management.gold_zone.incidents i


where i.updated_at > (select coalesce(max(created_at), dateadd('day', -1, current_timestamp())) from incident_management.gold_zone.incident_comment_history)
and i.updated_at >= dateadd('day', -1, current_timestamp())
and i.status = 'open'
