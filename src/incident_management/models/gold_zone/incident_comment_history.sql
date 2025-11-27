{{
    config(
        materialized='incremental'
        ,incremental_strategy='merge'
        ,unique_key=['id']
        ,merge_update_columns=['created_at', 'content', 'author_id', 'incident_number']
        ,description='Simplified incident comment history for tracking communication'
        ,tags=['daily']
    )
}}

select 
    slack_message_id as id,
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