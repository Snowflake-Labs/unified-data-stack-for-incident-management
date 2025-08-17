{{
  config(
    materialized='view',
    description='Active incidents requiring attention with SLA status and priority ordering'
  )
}}

SELECT 
    i.incident_number,
    i.title,
    i.status,
    i.priority,
    i.category AS category_name,  
    CONCAT(assignee.first_name, ' ', assignee.last_name) AS assignee_name,
    i.created_at,
    DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP()) AS age_hours,
    i.sla_due_at,
    CASE 
        WHEN i.sla_due_at IS NOT NULL AND i.sla_due_at < CURRENT_TIMESTAMP() THEN 'OVERDUE'
        WHEN i.sla_due_at IS NOT NULL AND i.sla_due_at < DATEADD('hour', 2, CURRENT_TIMESTAMP()) THEN 'DUE_SOON'
        ELSE 'ON_TRACK'
    END AS sla_status,
    i.affected_customers_count,
    i.estimated_revenue_impact,
    i.sla_breach,
    i.source_system,
    i.has_attachments
FROM {{ source('landing_zone', 'incidents') }} i
LEFT JOIN {{ source('landing_zone', 'users') }} assignee ON i.assignee_id = assignee.id
WHERE i.status = 'open'
ORDER BY 
    CASE i.priority 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END,
    i.created_at
