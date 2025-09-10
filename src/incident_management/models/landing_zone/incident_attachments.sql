{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        description='Materialized incident attachments table'
    )
}}

select 
    uuid_string() as id,
    incident_number,
    attachment_file,
    ts as uploaded_at
from {{ref('v_slack_msg_incident_number')}}
