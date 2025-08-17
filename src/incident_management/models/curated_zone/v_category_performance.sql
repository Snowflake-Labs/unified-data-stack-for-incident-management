{{
  config(
    materialized='view',
    description='Performance metrics grouped by incident category including resolution rates and timing'
  )
}}

SELECT 
    COALESCE(i.category, 'Uncategorized') AS category_name,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN i.status IN ('resolved', 'closed') THEN 1 END) AS resolved_incidents,
    ROUND(
        (COUNT(CASE WHEN i.status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage,
    AVG(
        CASE 
            WHEN i.resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', i.created_at, i.resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    AVG(
        CASE 
            WHEN i.acknowledged_at IS NOT NULL 
            THEN DATEDIFF('hour', i.created_at, i.acknowledged_at)
            ELSE NULL 
        END
    ) AS avg_acknowledgment_time_hours,
    AVG(
        CASE 
            WHEN i.first_response_at IS NOT NULL 
            THEN DATEDIFF('hour', i.created_at, i.first_response_at)
            ELSE NULL 
        END
    ) AS avg_first_response_time_hours,
    COUNT(CASE WHEN i.priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN i.priority = 'high' THEN 1 END) AS high_incidents,
    COUNT(CASE WHEN i.priority = 'medium' THEN 1 END) AS medium_incidents,
    COUNT(CASE WHEN i.priority = 'low' THEN 1 END) AS low_incidents,
    COUNT(CASE WHEN i.sla_breach = true THEN 1 END) AS sla_breaches,
    SUM(COALESCE(i.estimated_revenue_impact, 0)) AS total_revenue_impact,
    SUM(COALESCE(i.affected_customers_count, 0)) AS total_affected_customers
FROM {{ source('landing_zone', 'incidents') }} i
GROUP BY COALESCE(i.category, 'Uncategorized')
ORDER BY total_incidents DESC