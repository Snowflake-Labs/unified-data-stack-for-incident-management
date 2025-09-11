{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        description='Simplified incident comment history for tracking communication'
    )
}}

select 
    uuid_string() as id,
    i.incident_number,
    i.reportee_id as author_id,
    coalesce(sm.text, 'No related Slack message found') as content,
    current_timestamp() as created_at
from {{ref('incidents')}} i
inner join {{ref('v_qualify_slack_messages')}} sm 
on i.reportee_id = sm.username 
and i.external_source_id = sm.channel
and i.slack_message_id = sm.slack_message_id
