{{
  config(
    materialized='view',
    description='Comprehensive incident overview with calculated metrics and comment activity'
  )
}}

SELECT 
    i.incident_number,
    i.title,
    i.status,
    i.category,
    i.priority,
    
    -- People involved
    CONCAT(reporter.first_name, ' ', reporter.last_name) AS reporter_name,
    reporter.role AS reporter_role,
    reporter.department AS reporter_department,
    reporter.team AS reporter_team,
    CONCAT(assignee.first_name, ' ', assignee.last_name) AS assignee_name,
    assignee.role AS assignee_role,
    assignee.department AS assignee_department,
    assignee.team AS assignee_team,
    
    -- Business impact
    i.affected_customers_count,
    i.estimated_revenue_impact,
    i.customer_id,
    i.order_id,
    
    -- Timing metrics (original timestamps)
    i.created_at,
    i.acknowledged_at,
    i.first_response_at,
    i.resolved_at,
    i.closed_at,
    i.updated_at,
    i.sla_due_at,
    i.sla_breach,
    
    -- Calculated time metrics (in hours)
    CASE 
        WHEN i.acknowledged_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.acknowledged_at)
        ELSE NULL 
    END AS acknowledgment_time_hours,
    
    CASE 
        WHEN i.first_response_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.first_response_at)
        ELSE NULL 
    END AS first_response_time_hours,
    
    CASE 
        WHEN i.resolved_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.resolved_at)
        ELSE NULL 
    END AS resolution_time_hours,
    
    CASE 
        WHEN i.closed_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.closed_at)
        ELSE NULL 
    END AS total_time_hours,
    
    -- Current age for open incidents
    CASE 
        WHEN i.status = 'open'
        THEN DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP())
        ELSE NULL 
    END AS current_age_hours,
    
    -- Time until SLA breach (negative means already breached)
    CASE 
        WHEN i.sla_due_at IS NOT NULL AND i.status = 'open'
        THEN DATEDIFF('hour', CURRENT_TIMESTAMP(), i.sla_due_at)
        ELSE NULL 
    END AS hours_until_sla_breach,
    
    -- Resolution details
    i.resolution_summary,
    i.root_cause,
    i.resolution_category,
    i.source_system,
    i.external_source_id,
            
    -- Status indicators (using actual schema status values)
    CASE 
        WHEN i.status = 'open' THEN 'Active'
        WHEN i.status = 'resolved' THEN 'Resolved'
        WHEN i.status = 'closed' THEN 'Closed'
        ELSE 'Unknown'
    END AS status_category,
    
    -- Priority scoring for sorting
    CASE 
        WHEN i.priority = 'critical' THEN 4
        WHEN i.priority = 'high' THEN 3
        WHEN i.priority = 'medium' THEN 2
        WHEN i.priority = 'low' THEN 1
        ELSE 0
    END AS priority_score,
    
    -- Risk indicators
    CASE 
        WHEN i.sla_breach = true THEN 'SLA Breached'
        WHEN i.sla_due_at IS NOT NULL 
             AND i.status = 'open'
             AND DATEDIFF('hour', CURRENT_TIMESTAMP(), i.sla_due_at) <= 2 THEN 'SLA At Risk'
        WHEN i.status = 'open' 
             AND DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP()) > 24 THEN 'Long Running'
        ELSE 'Normal'
    END AS risk_indicator,
    
    -- Additional fields from updated schema
    i.has_attachments

FROM {{ source('landing_zone', 'incidents') }} i
LEFT JOIN {{ source('landing_zone', 'users') }} reporter ON i.reporter_id = reporter.id
LEFT JOIN {{ source('landing_zone', 'users') }} assignee ON i.assignee_id = assignee.id
