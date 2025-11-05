{{
  config(
    materialized='table',
    description='Monthly incident trends and metrics for reporting and analysis'
  )
}}

SELECT 
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status = 'resolved' OR status = 'closed' THEN 1 END) AS closed_incidents,
    COUNT(CASE WHEN status = 'open' THEN 1 END) AS open_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) AS high_priority_incidents,
    COUNT(CASE WHEN priority = 'medium' THEN 1 END) AS medium_priority_incidents,
    COUNT(CASE WHEN priority = 'low' THEN 1 END) AS low_priority_incidents,
    
    -- Category breakdown
    COUNT(CASE WHEN category = 'payment' THEN 1 END) AS payment_incidents,
    COUNT(CASE WHEN category = 'authentication' THEN 1 END) AS authentication_incidents,
    COUNT(CASE WHEN category = 'performance' THEN 1 END) AS performance_incidents,
    COUNT(CASE WHEN category = 'security' THEN 1 END) AS security_incidents,
    
    -- Source system breakdown
    COUNT(CASE WHEN source_system = 'monitoring' THEN 1 END) AS monitoring_incidents,
    COUNT(CASE WHEN source_system = 'customer_portal' THEN 1 END) AS customer_portal_incidents,
    COUNT(CASE WHEN source_system = 'manual' THEN 1 END) AS manual_incidents,
    
    -- Average resolution time for closed incidents (in hours)
    AVG(
        CASE 
            WHEN closed_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, closed_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    
    -- Incidents with attachments
    COUNT(CASE WHEN has_attachments = true THEN 1 END) AS incidents_with_attachments,
    
    -- Resolution rate percentage
    ROUND(
        (COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage
    
FROM {{ ref('incidents') }}
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC
