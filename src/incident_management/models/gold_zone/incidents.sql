-- Create only new incidents in this incremental mode; new incidents are detected by absence of an incident number from previous step in the pipeline or,
-- they are not related to any existing incident by title and text.
{{
    config(
        materialized='incremental'
        ,incremental_strategy='merge'
        ,unique_key='incident_number'
        ,merge_update_columns=['updated_at', 'slack_message_id', 'last_comment']
        ,description='Materialized incidents table with enriched data and calculated fields'
        ,tags=['daily']
    )
}}

-- Get recent open incidents for lookback when incident_code is null
with 

recent_open_incidents as (
    select * from {{ this }}
    where lower(status) = 'open' 
    and reportee_id is not null
    and created_at > dateadd('day', -7, current_timestamp())
)

, new_slack_messages as (
    select 
        lh.*
    from {{ref('v_qualify_slack_messages')}} lh 
    left join recent_open_incidents rh 
    on lh.slack_message_id = rh.slack_message_id
    where rh.slack_message_id is null
)

-- Split messages based on whether they have valid incident codes
, messages_with_incident_code as (
    select 
        * exclude(incident_number),
        parse_json(incident_number):incident_code::string as incident_number
    from new_slack_messages
    where not IS_NULL_VALUE(parse_json(incident_number):incident_code)
)

, messages_without_incident_code as (
    select 
        * exclude(incident_number),
        '' as incident_number
    from new_slack_messages
    where IS_NULL_VALUE(parse_json(incident_number):incident_code)
)

-- For messages without incident codes, try to find existing incidents
, messages_with_matching_incidents as (
    select 
        sm.*,
        ai_classify(sm.text, ['payment gateway error', 'login error', 'other']):labels[0] as text_category,
        roi.incident_number as existing_incident_number
    from messages_without_incident_code sm
    left join recent_open_incidents roi 
    on sm.channel = roi.external_source_id 
    and sm.username = roi.reportee_id 
    and ai_filter(
     prompt('The text category {0} is logically relatable to this record\'s category {1}', text_category, roi.category)
    )
)

-- Combine all messages with their appropriate incident numbers
, all_processed_messages as (
    -- Messages that already have incident codes
    select *, incident_number as final_incident_number
    from messages_with_incident_code
    
    union
    
    -- Messages without incident codes, use existing if found, otherwise generate new
    select 
        * exclude (existing_incident_number, text_category),
        coalesce(existing_incident_number, concat_ws('-', 'INC', '2025', randstr(3, random()))) as final_incident_number
    from messages_with_matching_incidents
)

, enriched_incidents as (
    select
        -- Core incident fields matching DDL schema
        case 
            when not IS_NULL_VALUE(parse_json(sri.incident_number):incident_code) then 
                parse_json(sri.incident_number):incident_code::string
            else sri.final_incident_number
        end as incident_number,        
        
        -- Image or Text Classification
        case 
            when sri.attachment_file is not null then 
                ai_classify(sri.attachment_file, ['payment gateway error', 'login error', 'other']):labels[0]
            else ai_classify(sri.text, ['payment gateway error', 'login error', 'other']):labels[0]
        end as category,
        ai_classify(sri.text, ['payment gateway error', 'login error', 'other']):labels[0] as title, 
        case 
            when category = 'payment gateway error' then 'critical'
            when category = 'login error' then 'high'
            else 'low'
        end as priority,
        
        -- Status tracking
        'open' as status,
        
        -- People involved
        '' as assignee_id,
        sri.reporter_id as reportee_id,
        
        -- Timestamps
        sri.ts as created_at,
        null as closed_at,
        sri.ts as updated_at,
        
        -- System fields
        'Slack' as source_system,
        sri.channel as external_source_id,
        sri.hasfiles as has_attachments,
        sri.slack_message_id,
        
        -- Latest comment
        sri.text as last_comment

        
    from all_processed_messages sri
)

select * 
from enriched_incidents