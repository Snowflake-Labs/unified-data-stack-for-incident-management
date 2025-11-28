{{
  config(
    materialized='table'
    ,description='Weekly incident trends for the last 12 weeks showing resolution patterns'
    ,tags=['weekly']
  )
}}

SELECT 
    DATE_TRUNC('week', created_at) AS week,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) AS resolved_incidents,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) AS closed_incidents,
    COUNT(CASE WHEN status = 'open' THEN 1 END) AS open_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) AS high_incidents,
    COUNT(CASE WHEN priority IN ('critical', 'high') THEN 1 END) AS high_severity_incidents,
    
    -- Category breakdown
    COUNT(CASE WHEN category = 'payment' THEN 1 END) AS payment_incidents,
    COUNT(CASE WHEN category = 'authentication' THEN 1 END) AS authentication_incidents,
    COUNT(CASE WHEN category = 'performance' THEN 1 END) AS performance_incidents,
    COUNT(CASE WHEN category = 'security' THEN 1 END) AS security_incidents,
    
    -- Source system breakdown
    COUNT(CASE WHEN source_system = 'monitoring' THEN 1 END) AS monitoring_incidents,
    COUNT(CASE WHEN source_system = 'customer_portal' THEN 1 END) AS customer_portal_incidents,
    
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
WHERE created_at >= DATEADD('year', -1, CURRENT_DATE())
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY week DESC
