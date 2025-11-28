{{
    config(
        materialized='incremental'
        ,incremental_strategy='merge'
        ,unique_key=['id']
        ,merge_update_columns=['uploaded_at', 'attachment_file']
        ,description='Materialized incident attachments table'
        ,tags=['daily']
    )
}}

select 
    dm.file_id as id,
    i.incident_number,
    to_file('{{ var("docs_stage_path") }}', dm.staged_file_path) as attachment_file,
    dm.event_ts as uploaded_at
from {{ref('incidents')}} i
inner join {{source('bronze_zone', 'doc_metadata')}} dm 
on i.has_attachments 
and i.reportee_id = dm.user_id 
and i.external_source_id = dm.channel_id
and i.created_at = dm.event_ts
