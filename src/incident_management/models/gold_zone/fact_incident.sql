{{ config(materialized='table', description='Unified fact table for incidents across ServiceNow and Slack', enabled=false) }}

with sn as (
  select
    incident_number,
    'ServiceNow' as source_system,
    external_source_id,

    -- People
    reportee_id,
    opened_by_user_id,
    assignee_id,
    assignment_group_id,

    -- Classification
    category,
    subcategory,
    business_service_id,
    service_offering_id,
    cmdb_ci_id,
    contact_type,

    -- Descriptions
    title,
    description,

    -- Priority/Impact/Urgency
    impact,
    urgency,
    priority,

    -- State/Lifecycle
    status,
    on_hold_reason,
    reopen_count,
    reassignment_count,

    -- Timestamps
    created_at,
    resolved_at,
    closed_at,
    updated_at,

    -- Resolution
    close_notes,
    close_code,
    resolved_by_user_id,

    -- Relationships
    parent_incident_number,
    problem_id,
    change_request,

    -- Major/Outage
    major_incident,
    major_incident_state,

    -- Slack-specific (not applicable)
    cast(null as boolean) as has_attachments,
    cast(null as varchar) as slack_message_id,
    cast(null as string) as last_comment
  from {{ ref('v_stg_servicenow_incidents') }}
),

slack as (
  select
    incident_number,
    'Slack' as source_system,
    external_source_id,

    -- People
    reportee_id,
    cast(null as string) as opened_by_user_id,
    assignee_id,
    cast(null as string) as assignment_group_id,

    -- Classification
    category,
    cast(null as string) as subcategory,
    cast(null as string) as business_service_id,
    cast(null as string) as service_offering_id,
    cast(null as string) as cmdb_ci_id,
    cast(null as string) as contact_type,

    -- Descriptions
    title,
    cast(null as string) as description,

    -- Priority/Impact/Urgency
    cast(null as number) as impact,
    cast(null as number) as urgency,
    case lower(priority)
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      when 'low' then 4
      else null
    end as priority,

    -- State/Lifecycle
    status,
    cast(null as string) as on_hold_reason,
    cast(null as number) as reopen_count,
    cast(null as number) as reassignment_count,

    -- Timestamps
    created_at,
    cast(null as timestamp_tz) as resolved_at,
    closed_at,
    updated_at,

    -- Resolution
    cast(null as string) as close_notes,
    cast(null as string) as close_code,
    cast(null as string) as resolved_by_user_id,

    -- Relationships
    cast(null as string) as parent_incident_number,
    cast(null as string) as problem_id,
    cast(null as string) as change_request,

    -- Major/Outage
    cast(false as boolean) as major_incident,
    cast(null as string) as major_incident_state,

    -- Slack-specific
    has_attachments,
    slack_message_id,
    last_comment
  from {{ ref('incidents') }}
)

select * from sn
union all
select * from slack


