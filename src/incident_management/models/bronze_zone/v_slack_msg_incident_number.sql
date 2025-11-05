{{
    config(
        materialized='view',
        description=''
        ,enable=false
    )
}}

with 
recent_recorded_incidents as (
    select * from {{ ref('incidents') }}
    where status = 'open' and reportee_id is not null
    and created_at > dateadd('day', -7, current_timestamp())
), -- match only open incidents from the last 7 days to avoid stale incidents that are past SLA expiry
incident_number_in_slack_message as (
    select * from {{ ref('v_qualify_slack_messages') }}
    where not IS_NULL_VALUE(parse_json(incident_number):incident_code)
),
incident_number_not_in_slack_message as (
    select * from {{ ref('v_qualify_slack_messages') }}
    where IS_NULL_VALUE(parse_json(incident_number):incident_code)
)

select * 
from incident_number_in_slack_message sm

union all

select 
    sm.* exclude (incident_number),
    i.incident_number as incident_number
from incident_number_not_in_slack_message sm
left join recent_recorded_incidents i 
on sm.channel = i.external_source_id  and i.reportee_id =sm.username -- where incident was reported from the same channel and the reportee is the same as the reporter
and ai_filter(prompt($$
    Return true if this incident title {0} is refers to the problem now being described in this recent Slack message {1}, else return false.
    If multiple incidents are related, return true for the most recent incident by created_at timestamp.
    Only one can be true at a time.
    Do not add any explanation in the response.
$$, i.title, sm.text)) -- where the incident title is relatable to the recent Slack message text

