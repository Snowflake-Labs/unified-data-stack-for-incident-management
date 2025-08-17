{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        unique_key='incident_number',
        description='Materialized incidents table with enriched data and calculated fields'
    )
}}

with slack_reported_incidents as (
    select * from {{ source('landing_zone', 'v_qualify_slack_messages') }}
    where incident_number is null
),

reporter_users as (
    select * from {{ source('landing_zone', 'users') }}
),

enriched_incidents as (
    select
        -- Core incident fields
        concat_ws('-', 'INC', '2025', randstr(3,  random())) as incident_number,
        ai_complete('claude-3-5-sonnet', prompt(
            $$
            Generate a title for the incident based on the description.
            Examples:
            - "Website Performance Degradation"
            - "Payment Gateway Outage"
            - "Customer Login Issues"
            $$,
            i.text
        )) as title,
        'open' as status,
        
        -- User information
        r.id as reporter_id,
        "" as assignee_id,
        
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
        
        -- SLA fields
        i.sla_breach,
        case
            when priority = 'critical' then date_add('hour', 1, current_timestamp())
            when priority = 'high' then date_add('hour', 4, current_timestamp())
            when priority = 'medium' then date_add('day', 3, current_timestamp())
            else date_add('day', 7, current_timestamp())
        end as sla_due_at,
        
        -- Additional fields
        "" as resolution_summary,
        "" as root_cause,
        "" as resolution_category,
        "Slack" as source_system,
        i.channel as external_source_id,    
        
        -- Calculated fields
        ai_classify(img, ['payment gateway error', 'login error', 'other']):labels[0] as category,
        case 
            when category = 'payment gateway error' then 'critical'
            when category = 'login error' then 'high'
            else 'low'
        end as priority,
        
        -- Attachment indicator
        i.hasfiles as has_attachments
        
    from slack_reported_incidents i
    left join reporter_users r on i.username = split(r.email, '@')[0]
)

select * from enriched_incidents
