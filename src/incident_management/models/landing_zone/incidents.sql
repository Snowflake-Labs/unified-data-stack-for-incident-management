{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        description='Materialized incidents table with enriched data and calculated fields'
    )
}}

-- Create only new incidents in this incremental mode; new incidents are detected by absence of an incident number from previous step in the pipeline
with slack_reported_incidents as (
    select * from {{ ref('v_qualify_slack_messages') }}
    where IS_NULL_VALUE(parse_json(incident_number):incident_code)
),

enriched_incidents as (
    select
        -- Core incident fields matching DDL schema
        concat_ws('-', 'INC', '2025', randstr(3,  random())) as incident_number,
        ai_complete('claude-3-5-sonnet', prompt(
            $$
            Generate a title for the incident based on the given description {0}.
            Examples:
            - "Website Performance Degradation"
            - "Payment Gateway Outage"
            - "Customer Login Issues"
            $$,
            i.text
        )) as title,
        
        -- Classification
        ai_classify(i.attachment_file, ['payment gateway error', 'login error', 'other']):labels[0] as category,
        case 
            when category = 'payment gateway error' then 'critical'
            when category = 'login error' then 'high'
            else 'low'
        end as priority,
        
        -- Status tracking
        'open' as status,
        
        -- People involved
        '' as assignee_id,
        
        -- Timestamps
        current_timestamp() as created_at,
        null as closed_at,
        current_timestamp() as updated_at,
        
        -- System fields
        'Slack' as source_system,
        i.channel as external_source_id,
        i.hasfiles as has_attachments
        
    from slack_reported_incidents i
)

select * 
from enriched_incidents