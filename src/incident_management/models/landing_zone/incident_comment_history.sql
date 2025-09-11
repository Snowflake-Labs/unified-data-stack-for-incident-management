{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        description='Simplified incident comment history for tracking communication'
    )
}}

select 
    uuid_string() as id,
    incident_number,
    reportee_id as author_id,
    text as content,
    current_timestamp() as created_at
from {{ref('incidents')}}
