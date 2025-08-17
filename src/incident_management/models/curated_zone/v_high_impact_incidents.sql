{{
  config(
    materialized='view',
    description='High-impact incidents with calculated business impact scores and priority filtering'
  )
}}

SELECT 
    i.incident_number,
    i.title,
    i.status,
    i.priority,
    i.category AS category_name,
    i.affected_customers_count,
    i.estimated_revenue_impact,
    i.created_at,
    i.acknowledged_at,
    i.first_response_at,
    i.resolved_at,
    i.closed_at,
    
    -- Time to resolution or current age
    CASE 
        WHEN i.resolved_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.resolved_at)
        ELSE DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP())
    END AS time_hours,
    
    -- Business impact score (simplified calculation)
    CASE
        WHEN i.priority = 'critical' THEN 100
        WHEN i.priority = 'high' THEN 50
        WHEN i.priority = 'medium' THEN 25
        WHEN i.priority = 'low' THEN 10
        ELSE 5
    END 
    + COALESCE(i.affected_customers_count, 0) * 0.1 
    + COALESCE(i.estimated_revenue_impact, 0) / 1000 AS business_impact_score,
    
    -- Additional fields from schema
    i.sla_breach,
    i.sla_due_at,
    i.source_system,
    i.external_source_id,
    i.has_attachments,
    i.customer_id,
    i.order_id,
    i.resolution_summary,
    i.root_cause,
    i.resolution_category

FROM {{ source('landing_zone', 'incidents') }} i
WHERE i.priority IN ('critical', 'high') 
   OR i.affected_customers_count > 10 
   OR i.estimated_revenue_impact > 1000
ORDER BY business_impact_score DESC, i.created_at DESC
