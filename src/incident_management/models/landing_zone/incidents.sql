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
    select * from {{ ref('v_qualify_slack_messages') }}
),

-- Get recent open incidents for lookback when incident_code is null
recent_open_incidents as (
    select * from {{ this }}
    where status = 'open' 
    and reportee_id is not null
    and created_at > dateadd('day', -7, current_timestamp())
),

-- Split messages based on whether they have valid incident codes
messages_with_incident_code as (
    select *
    from slack_reported_incidents
    where not IS_NULL_VALUE(parse_json(incident_number):incident_code)
),

messages_without_incident_code as (
    select *
    from slack_reported_incidents
    where IS_NULL_VALUE(parse_json(incident_number):incident_code)
),

-- For messages without incident codes, try to find existing incidents
messages_with_found_incidents as (
    select 
        sm.*,
        roi.incident_number as existing_incident_number
    from messages_without_incident_code sm
    left join recent_open_incidents roi 
    on sm.channel = roi.external_source_id 
    and roi.reportee_id = sm.username
    and ai_filter(prompt($$
        Return true if this incident title {0} refers to the problem now being described in this recent Slack message {1}, else return false.
        If multiple incidents are related, return true for the most recent incident by created_at timestamp.
        Only one can be true at a time.
        Do not add any explanation in the response.
    $$, roi.title, sm.text))
),

-- Combine all messages with their appropriate incident numbers
all_processed_messages as (
    -- Messages that already have incident codes
    select *, incident_number as final_incident_number
    from messages_with_incident_code
    
    union all
    
    -- Messages without incident codes, use existing if found, otherwise generate new
    select 
        * exclude (existing_incident_number),
        coalesce(existing_incident_number, concat_ws('-', 'INC', '2025', randstr(3, random()))) as final_incident_number
    from messages_with_found_incidents
),

enriched_incidents as (
    select
        -- Core incident fields matching DDL schema
        case 
            when not IS_NULL_VALUE(parse_json(sri.incident_number):incident_code) then 
                parse_json(sri.incident_number):incident_code::string
            else sri.final_incident_number
        end as incident_number,        
        
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
        sri.hasfiles as has_attachments,
        sri.slack_message_id
        
    from all_processed_messages sri
)

select * 
from enriched_incidents