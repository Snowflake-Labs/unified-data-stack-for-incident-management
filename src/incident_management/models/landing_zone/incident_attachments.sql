{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        description='Materialized incident attachments table'
    )
}}

select 
    uuid_string() as id,
    i.incident_number,
    sm.attachment_file,
    sm.ts as uploaded_at
from {{ref('incidents')}} i
inner join {{ref('v_qualify_slack_messages')}} sm 
on sm.hasfiles = true 
and i.reportee_id = sm.username 
and i.external_source_id = sm.channel
and i.slack_message_id = sm.slack_message_id
and sm.attachment_file is not null
