{{
  config(
    materialized='table'
    , description='Active incidents requiring attention with SLA status and priority ordering'
    , tags=['daily']
  )
}}

SELECT 
    i.incident_number,
    i.title,
    i.category,
    i.priority,
    i.status,
    i.assignee_id,
    CONCAT(assignee.first_name, ' ', assignee.last_name) AS assignee_name,
    i.reportee_id,
    CONCAT(reportee.first_name, ' ', reportee.last_name) AS reportee_name,
    i.created_at,
    i.updated_at,
    DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP()) AS age_hours,
    i.source_system,
    i.external_source_id,
    i.has_attachments
FROM {{ ref('incidents') }} i
LEFT JOIN {{ ref('users') }} assignee ON i.assignee_id = assignee.id
LEFT JOIN {{ ref('users') }} reportee ON i.reportee_id = reportee.id
WHERE i.status = 'open'
