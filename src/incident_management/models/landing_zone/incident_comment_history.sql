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
    i.last_comment as content,
    current_timestamp() as created_at
from {{ref('incidents')}} i

{% if is_incremental() %}
where i.updated_at > (select coalesce(max(created_at), dateadd('day', -1, current_timestamp())) from {{this}})
and i.updated_at >= dateadd('day', -1, current_timestamp())
and i.status = 'open'
{% endif %}