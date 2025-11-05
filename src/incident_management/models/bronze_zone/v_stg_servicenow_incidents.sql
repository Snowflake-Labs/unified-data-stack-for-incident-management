{{ config(
  materialized='view', 
  description='Staging ServiceNow incidents normalized to warehouse conventions', 
  enabled=false) 
}}

select
  inc.number                               as incident_number,
  inc.sys_id                               as external_source_id,
  'ServiceNow'                             as source_system,

  -- People
  inc.caller_id                            as reportee_id,
  inc.opened_by                            as opened_by_user_id,
  inc.assigned_to                          as assignee_id,
  inc.assignment_group                     as assignment_group_id,

  -- Classification
  inc.category,
  inc.subcategory,
  inc.business_service                     as business_service_id,
  inc.service_offering                     as service_offering_id,
  inc.cmdb_ci                              as cmdb_ci_id,
  inc.contact_type,

  -- Descriptions
  inc.short_description                    as title,
  inc.description,

  -- Impact/Priority
  try_to_number(inc.impact)                as impact,
  try_to_number(inc.urgency)               as urgency,
  try_to_number(inc.priority)              as priority,

  -- State/Lifecycle
  lower(inc.state)                         as status,
  inc.on_hold_reason,
  try_to_number(inc.reopen_count)          as reopen_count,
  try_to_number(inc.reassignment_count)    as reassignment_count,

  -- Timestamps
  to_timestamp_tz(inc.opened_at)           as created_at,
  to_timestamp_tz(inc.resolved_at)         as resolved_at,
  to_timestamp_tz(inc.closed_at)           as closed_at,
  to_timestamp_tz(inc.sys_updated_on)      as updated_at,

  -- Resolution
  inc.close_notes,
  inc.close_code,
  inc.resolved_by                          as resolved_by_user_id,

  -- Relationships
  inc.parent_incident                      as parent_incident_number,
  inc.problem_id,
  inc.change_request,

  -- Major/Outage
  try_to_boolean(inc.major_incident)       as major_incident,
  inc.major_incident_state

from {{ source('servicenow', 'incident') }} inc