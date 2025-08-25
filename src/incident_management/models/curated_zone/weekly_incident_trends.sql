{{
  config(
    materialized='table',
    description='Weekly incident trends for the last 12 weeks showing resolution patterns'
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
    COUNT(CASE WHEN sla_breach = true THEN 1 END) AS sla_breaches,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    AVG(
        CASE 
            WHEN acknowledged_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, acknowledged_at)
            ELSE NULL 
        END
    ) AS avg_acknowledgment_time_hours,
    AVG(
        CASE 
            WHEN first_response_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, first_response_at)
            ELSE NULL 
        END
    ) AS avg_first_response_time_hours,
    SUM(COALESCE(estimated_revenue_impact, 0)) AS total_revenue_impact,
    SUM(COALESCE(affected_customers_count, 0)) AS total_affected_customers,
    ROUND(
        (COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage
FROM {{ source('landing_zone', 'incidents') }}
WHERE created_at >= DATEADD('week', -12, CURRENT_DATE())
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY week DESC
