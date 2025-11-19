

select 
    dm.file_id as id,
    i.incident_number,
    to_file('@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS', dm.staged_file_path) as attachment_file,
    dm.event_ts as uploaded_at
from incident_management.gold_zone.incidents i
inner join incident_management.bronze_zone.doc_metadata dm 
on i.has_attachments 
and i.reportee_id = dm.user_id 
and i.external_source_id = dm.channel_id
and i.created_at = dm.event_ts