{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        unique_key='id',
        description='Simplified incident comment history for tracking communication'
    )
}}

select 
    uuid_string() as id,
    incident_number,
    reporter_id as author_id,
    text as content,
    current_timestamp() as created_at
from {{ref('v_slack_msg_incident_number')}}
