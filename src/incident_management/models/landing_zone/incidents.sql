{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        unique_key='incident_number',
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
        -- Core incident fields
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
        'open' as status,
        
        -- User information
        i.reporter_id,
        '' as assignee_id,
        '' as customer_id,
        '' as order_id,
        
        -- Business impact
        0 as affected_customers_count,
        0 as estimated_revenue_impact,
        
        -- Timestamps
        current_timestamp() as created_at,
        null as acknowledged_at,
        null as first_response_at,
        null as resolved_at,
        null as closed_at,
        current_timestamp() as updated_at,
                
        -- Additional fields
        '' as resolution_summary,
        '' as root_cause,
        '' as resolution_category,
        'Slack' as source_system,
        i.channel as external_source_id,    
        
        -- Calculated fields
        ai_classify(i.attachment_file, ['payment gateway error', 'login error', 'other']):labels[0] as category,
        case 
            when category = 'payment gateway error' then 'critical'
            when category = 'login error' then 'high'
            else 'low'
        end as priority,
                -- SLA fields
        null as sla_breach,
        case
            when priority = 'critical' then dateadd('hour', 1, current_timestamp())
            when priority = 'high' then dateadd('hour', 4, current_timestamp())
            when priority = 'medium' then dateadd('day', 3, current_timestamp())
            else dateadd('day', 7, current_timestamp())
        end as sla_due_at,

        -- Attachment indicator
        i.hasfiles as has_attachments
        
    from slack_reported_incidents i
)

select * 
from enriched_incidents
{% if is_incremental() %}
WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
