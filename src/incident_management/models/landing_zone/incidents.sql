{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='incident_number',
        description='Materialized incidents table with enriched data and calculated fields'
    )
}}

-- Create only new incidents in this incremental mode; new incidents are detected by absence of an incident number from previous step in the pipeline
with slack_reported_incidents as (
    select * from {{ ref('v_qualifyv_slack_msg_incident_number') }}
),

enriched_incidents as (
    select
        -- Core incident fields matching DDL schema
        coalesce(sri.incident_number, concat_ws('-', 'INC', '2025', randstr(3,  random()))) as incident_number,        
        
        -- Image Classification
        ai_classify(sri.attachment_file, ['payment gateway error', 'login error', 'other']):labels[0] as category,
        category as title, --reuse the category as the title
        case 
            when category = 'payment gateway error' then 'critical'
            when category = 'login error' then 'high'
            else 'low'
        end as priority,
        
        -- Status tracking
        'open' as status,
        
        -- People involved
        '' as assignee_id,
        sri.username as reportee_id,
        
        -- Timestamps
        current_timestamp() as created_at,
        null as closed_at,
        current_timestamp() as updated_at,
        
        -- System fields
        'Slack' as source_system,
        sri.channel as external_source_id,
        sri.hasfiles as has_attachments
        
    from slack_reported_incidents sri
)

select * 
from enriched_incidents