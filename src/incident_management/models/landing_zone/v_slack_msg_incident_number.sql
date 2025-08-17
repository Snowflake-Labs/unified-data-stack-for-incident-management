{{
    config(
        materialized='view',
        description=''
    )
}}


with recent_recorded_incidents as (
    select * from {{ ref('incidents') }}
    where status = 'open' 
    and created_at > date_add('day', -30, current_timestamp())
)

select 
    sm.*,
    i.incident_number
from {{ source('landing_zone', 'v_qualify_slack_messages') }} sm
left join recent_recorded_incidents i 
on sm.channel = i.external_source_id  -- where incident was reported from the same channel
and ai_filter(prompt($$
    If this incident title {0} is refers to the problem now being described in this recent Slack message {1}. 
    If it does, return true. If it does not, return false.
    If multiple incidents are related, return true for the most recent incident.
    Only one can be true at a time.
$$, i.title, sm.text)) -- where the incident title is relatable to the recent Slack message text

