{{
  config(
    materialized='table',
    description='Monthly incident trends and metrics for reporting and analysis'
  )
}}

SELECT 
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) AS resolved_incidents,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) AS closed_incidents,
    COUNT(CASE WHEN status = 'open' THEN 1 END) AS open_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) AS high_priority_incidents,
    COUNT(CASE WHEN priority = 'medium' THEN 1 END) AS medium_priority_incidents,
    COUNT(CASE WHEN priority = 'low' THEN 1 END) AS low_priority_incidents,
    COUNT(CASE WHEN sla_breach = true THEN 1 END) AS sla_breaches,
    
    -- Average resolution time for resolved incidents (in hours)
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    
    -- Average acknowledgment time (in hours)
    AVG(
        CASE 
            WHEN acknowledged_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, acknowledged_at)
            ELSE NULL 
        END
    ) AS avg_acknowledgment_time_hours,
    
    -- Average first response time (in hours)
    AVG(
        CASE 
            WHEN first_response_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, first_response_at)
            ELSE NULL 
        END
    ) AS avg_first_response_time_hours,
    
    -- Total estimated revenue impact
    SUM(COALESCE(estimated_revenue_impact, 0)) AS total_estimated_revenue_impact,
    
    -- Total affected customers
    SUM(COALESCE(affected_customers_count, 0)) AS total_affected_customers,
    
    -- Resolution rate percentage
    ROUND(
        (COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage
    
FROM {{ source('landing_zone', 'incidents') }}
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC
