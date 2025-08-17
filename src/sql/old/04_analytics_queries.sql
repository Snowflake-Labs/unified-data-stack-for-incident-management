-- Advanced Analytics Queries for Data Mining and Insights - Snowflake Version
-- These queries provide deep insights into incident patterns and operational metrics

-- =============================================
-- PREDICTIVE ANALYTICS QUERIES
-- =============================================

-- Identify incidents likely to require escalation based on historical patterns
WITH escalation_patterns AS (
    SELECT 
        ic.name AS category_name,
        i.priority,
        COUNT(*) as total_incidents,
        COUNT(CASE WHEN DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP())) > 24 THEN 1 END) as long_running_incidents,
        (COUNT(CASE WHEN DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP())) > 24 THEN 1 END)::DECIMAL / COUNT(*)) as long_running_rate
    FROM incidents i
    LEFT JOIN incident_categories ic ON i.category_id = ic.id
    WHERE i.created_at >= DATEADD('day', -90, CURRENT_DATE())
    GROUP BY ic.name, i.priority
    HAVING COUNT(*) >= 5
)
SELECT 
    category_name,
    priority,
    total_incidents,
    long_running_incidents,
    ROUND(long_running_rate * 100, 2) as long_running_rate_percentage,
    CASE 
        WHEN long_running_rate > 0.3 THEN 'High Risk'
        WHEN long_running_rate > 0.15 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as escalation_risk
FROM escalation_patterns
ORDER BY long_running_rate DESC;

-- =============================================
-- SEASONAL AND TEMPORAL ANALYSIS
-- =============================================

-- Day-of-week incident patterns
SELECT 
    DAYOFWEEK(created_at) as day_of_week,
    CASE DAYOFWEEK(created_at)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    COUNT(*) as total_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) as critical_incidents,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
        END
    ) as avg_resolution_hours,
    COUNT(CASE WHEN sla_breach = true THEN 1 END) as sla_breaches
FROM incidents
WHERE created_at >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY DAYOFWEEK(created_at)
ORDER BY day_of_week;

-- Hour-of-day incident patterns
SELECT 
    EXTRACT('hour', created_at) as hour_of_day,
    COUNT(*) as total_incidents,
    COUNT(CASE WHEN priority IN ('critical', 'high') THEN 1 END) as high_severity_incidents,
    ROUND(
        (COUNT(CASE WHEN priority IN ('critical', 'high') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) as high_severity_percentage
FROM incidents
WHERE created_at >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY EXTRACT('hour', created_at)
ORDER BY hour_of_day;

-- =============================================
-- CUSTOMER IMPACT ANALYSIS
-- =============================================

-- Customer impact distribution analysis
WITH impact_buckets AS (
    SELECT 
        i.id,
        i.incident_number,
        i.affected_customers_count,
        i.estimated_revenue_impact,
        CASE 
            WHEN i.affected_customers_count = 0 THEN 'No Customer Impact'
            WHEN i.affected_customers_count <= 10 THEN '1-10 Customers'
            WHEN i.affected_customers_count <= 100 THEN '11-100 Customers'
            WHEN i.affected_customers_count <= 1000 THEN '101-1000 Customers'
            WHEN i.affected_customers_count <= 10000 THEN '1001-10000 Customers'
            ELSE '>10000 Customers'
        END as customer_impact_bucket,
        CASE 
            WHEN i.estimated_revenue_impact = 0 THEN 'No Revenue Impact'
            WHEN i.estimated_revenue_impact <= 1000 THEN '$1-1000'
            WHEN i.estimated_revenue_impact <= 10000 THEN '$1001-10000'
            WHEN i.estimated_revenue_impact <= 100000 THEN '$10001-100000'
            ELSE '>$100000'
        END as revenue_impact_bucket,
        DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP())) as resolution_hours
    FROM incidents i
    WHERE i.created_at >= DATEADD('day', -90, CURRENT_DATE())
)
SELECT 
    customer_impact_bucket,
    revenue_impact_bucket,
    COUNT(*) as incident_count,
    AVG(resolution_hours) as avg_resolution_hours,
    SUM(affected_customers_count) as total_customers_affected,
    SUM(estimated_revenue_impact) as total_revenue_impact
FROM impact_buckets
GROUP BY customer_impact_bucket, revenue_impact_bucket
ORDER BY 
    CASE customer_impact_bucket
        WHEN 'No Customer Impact' THEN 1
        WHEN '1-10 Customers' THEN 2
        WHEN '11-100 Customers' THEN 3
        WHEN '101-1000 Customers' THEN 4
        WHEN '1001-10000 Customers' THEN 5
        ELSE 6
    END,
    CASE revenue_impact_bucket
        WHEN 'No Revenue Impact' THEN 1
        WHEN '$1-1000' THEN 2
        WHEN '$1001-10000' THEN 3
        WHEN '$10001-100000' THEN 4
        ELSE 5
    END;

-- =============================================
-- RESOLUTION EFFICIENCY ANALYSIS
-- =============================================

-- Resolution time trends by category and priority
SELECT 
    ic.name as category_name,
    i.priority,
    DATE_TRUNC('week', i.created_at) as week,
    COUNT(*) as incidents_resolved,
    AVG(DATEDIFF('hour', i.created_at, i.resolved_at)) as avg_resolution_hours,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY DATEDIFF('hour', i.created_at, i.resolved_at)
    ) as median_resolution_hours,
    PERCENTILE_CONT(0.95) WITHIN GROUP (
        ORDER BY DATEDIFF('hour', i.created_at, i.resolved_at)
    ) as p95_resolution_hours
FROM incidents i
JOIN incident_categories ic ON i.category_id = ic.id
WHERE i.resolved_at IS NOT NULL
AND i.created_at >= DATEADD('week', -12, CURRENT_DATE())
GROUP BY ic.name, i.priority, DATE_TRUNC('week', i.created_at)
HAVING COUNT(*) >= 3
ORDER BY week DESC, category_name, i.priority;

-- =============================================
-- COST ANALYSIS
-- =============================================

-- Estimated cost impact by team and category
WITH team_costs AS (
    SELECT 
        u.team,
        u.department,
        ic.name as category_name,
        COUNT(*) as incidents_handled,
        SUM(COALESCE(i.estimated_revenue_impact, 0)) as revenue_impact,
        SUM(
            DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP()))
        ) as total_hours_spent,
        
        -- Estimate labor cost (assuming $75/hour average)
        SUM(
            DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP()))
        ) * 75 as estimated_labor_cost,
        
        AVG(
            DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP()))
        ) as avg_time_per_incident
        
    FROM incidents i
    JOIN users u ON i.assignee_id = u.id
    LEFT JOIN incident_categories ic ON i.category_id = ic.id
    WHERE i.created_at >= DATEADD('day', -90, CURRENT_DATE())
    AND u.team IS NOT NULL
    GROUP BY u.team, u.department, ic.name
)
SELECT 
    team,
    department,
    category_name,
    incidents_handled,
    ROUND(revenue_impact, 2) as revenue_impact,
    ROUND(total_hours_spent, 2) as total_hours_spent,
    ROUND(estimated_labor_cost, 2) as estimated_labor_cost,
    ROUND(revenue_impact + estimated_labor_cost, 2) as total_estimated_cost,
    ROUND(avg_time_per_incident, 2) as avg_hours_per_incident
FROM team_costs
WHERE incidents_handled >= 3
ORDER BY total_estimated_cost DESC;

-- =============================================
-- PROACTIVE MONITORING QUERIES
-- =============================================

-- Early warning indicators
SELECT 
    'Incidents Created Today' as metric,
    COUNT(*)::STRING as current_value,
    CASE 
        WHEN COUNT(*) > (
            SELECT AVG(daily_count) * 1.5 
            FROM (
                SELECT DATE(created_at), COUNT(*) as daily_count 
                FROM incidents 
                WHERE created_at >= DATEADD('day', -30, CURRENT_DATE())
                GROUP BY DATE(created_at)
            ) daily_stats
        ) THEN 'ALERT: Unusual spike in incidents'
        ELSE 'Normal'
    END as status
FROM incidents 
WHERE DATE(created_at) = CURRENT_DATE()

UNION ALL

SELECT 
    'Critical Incidents Open >2 Hours',
    COUNT(*)::STRING,
    CASE 
        WHEN COUNT(*) > 2 THEN 'ALERT: Multiple critical incidents open'
        WHEN COUNT(*) > 0 THEN 'WARNING: Critical incident(s) open'
        ELSE 'Normal'
    END
FROM incidents 
WHERE priority = 'critical' 
AND status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor')
AND created_at < DATEADD('hour', -2, CURRENT_TIMESTAMP())

UNION ALL

SELECT 
    'Unassigned Incidents >1 Hour',
    COUNT(*)::STRING,
    CASE 
        WHEN COUNT(*) > 5 THEN 'ALERT: Many unassigned incidents'
        WHEN COUNT(*) > 2 THEN 'WARNING: Some unassigned incidents'
        ELSE 'Normal'
    END
FROM incidents 
WHERE assignee_id IS NULL
AND status IN ('open', 'in_progress')
AND created_at < DATEADD('hour', -1, CURRENT_TIMESTAMP());

-- =============================================
-- PERFORMANCE BENCHMARKING
-- =============================================

-- Compare current month vs previous month performance
WITH current_month AS (
    SELECT 
        COUNT(*) as total_incidents,
        COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END) as resolved_incidents,
        AVG(
            CASE 
                WHEN resolved_at IS NOT NULL 
                THEN DATEDIFF('hour', created_at, resolved_at)
            END
        ) as avg_resolution_hours,
        COUNT(CASE WHEN sla_breach = true THEN 1 END) as sla_breaches,
        SUM(COALESCE(estimated_revenue_impact, 0)) as total_revenue_impact
    FROM incidents 
    WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE())
),
previous_month AS (
    SELECT 
        COUNT(*) as total_incidents,
        COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END) as resolved_incidents,
        AVG(
            CASE 
                WHEN resolved_at IS NOT NULL 
                THEN DATEDIFF('hour', created_at, resolved_at)
            END
        ) as avg_resolution_hours,
        COUNT(CASE WHEN sla_breach = true THEN 1 END) as sla_breaches,
        SUM(COALESCE(estimated_revenue_impact, 0)) as total_revenue_impact
    FROM incidents 
    WHERE created_at >= DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE()))
    AND created_at < DATE_TRUNC('month', CURRENT_DATE())
)
SELECT 
    'Total Incidents' as metric,
    cm.total_incidents as current_month,
    pm.total_incidents as previous_month,
    ROUND(
        ((cm.total_incidents - pm.total_incidents)::DECIMAL / NULLIF(pm.total_incidents, 0)) * 100, 2
    ) as percentage_change
FROM current_month cm, previous_month pm

UNION ALL

SELECT 
    'Resolution Rate %',
    ROUND((cm.resolved_incidents::DECIMAL / NULLIF(cm.total_incidents, 0)) * 100, 2)::NUMBER,
    ROUND((pm.resolved_incidents::DECIMAL / NULLIF(pm.total_incidents, 0)) * 100, 2)::NUMBER,
    ROUND(
        (cm.resolved_incidents::DECIMAL / NULLIF(cm.total_incidents, 0)) * 100 - 
        (pm.resolved_incidents::DECIMAL / NULLIF(pm.total_incidents, 0)) * 100, 2
    )
FROM current_month cm, previous_month pm

UNION ALL

SELECT 
    'Avg Resolution Hours',
    ROUND(cm.avg_resolution_hours, 2)::NUMBER,
    ROUND(pm.avg_resolution_hours, 2)::NUMBER,
    ROUND(
        ((cm.avg_resolution_hours - pm.avg_resolution_hours) / NULLIF(pm.avg_resolution_hours, 0)) * 100, 2
    )
FROM current_month cm, previous_month pm

UNION ALL

SELECT 
    'SLA Breaches',
    cm.sla_breaches::NUMBER,
    pm.sla_breaches::NUMBER,
    CASE 
        WHEN pm.sla_breaches > 0 
        THEN ROUND(((cm.sla_breaches - pm.sla_breaches)::DECIMAL / pm.sla_breaches) * 100, 2)
        ELSE NULL
    END
FROM current_month cm, previous_month pm;

-- =============================================
-- ADVANCED PATTERN ANALYSIS
-- =============================================

-- Incident clustering by time and characteristics
WITH incident_clusters AS (
    SELECT 
        i.*,
        LAG(i.created_at) OVER (ORDER BY i.created_at) as prev_incident_time,
        DATEDIFF('minute', LAG(i.created_at) OVER (ORDER BY i.created_at), i.created_at) as minutes_since_last
    FROM incidents i
    WHERE i.created_at >= DATEADD('day', -30, CURRENT_DATE())
)
SELECT 
    DATE(created_at) as incident_date,
    COUNT(*) as total_incidents,
    COUNT(CASE WHEN minutes_since_last <= 60 THEN 1 END) as clustered_incidents,
    ROUND(
        (COUNT(CASE WHEN minutes_since_last <= 60 THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) as clustering_percentage,
    AVG(COALESCE(minutes_since_last, 0)) as avg_minutes_between_incidents
FROM incident_clusters
GROUP BY DATE(created_at)
HAVING COUNT(*) >= 3
ORDER BY incident_date DESC;

-- Team workload distribution
SELECT 
    u.team,
    u.department,
    COUNT(*) as total_assigned,
    COUNT(CASE WHEN i.status IN ('open', 'in_progress') THEN 1 END) as currently_active,
    COUNT(CASE WHEN i.priority = 'critical' THEN 1 END) as critical_incidents,
    AVG(DATEDIFF('hour', i.created_at, COALESCE(i.resolved_at, CURRENT_TIMESTAMP()))) as avg_handling_time,
    ROUND(
        COUNT(*)::DECIMAL / (
            SELECT COUNT(*) 
            FROM incidents 
            WHERE assignee_id IS NOT NULL 
            AND created_at >= DATEADD('day', -30, CURRENT_DATE())
        ) * 100, 2
    ) as workload_percentage
FROM incidents i
JOIN users u ON i.assignee_id = u.id
WHERE i.created_at >= DATEADD('day', -30, CURRENT_DATE())
AND u.team IS NOT NULL
GROUP BY u.team, u.department
ORDER BY total_assigned DESC;

-- Resolution effectiveness by time of day
SELECT 
    EXTRACT('hour', created_at) as hour_created,
    COUNT(*) as total_incidents,
    AVG(DATEDIFF('hour', created_at, resolved_at)) as avg_resolution_hours,
    COUNT(CASE WHEN sla_breach = false THEN 1 END) as within_sla,
    ROUND(
        (COUNT(CASE WHEN sla_breach = false THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) as sla_compliance_rate
FROM incidents
WHERE resolved_at IS NOT NULL
AND created_at >= DATEADD('day', -60, CURRENT_DATE())
GROUP BY EXTRACT('hour', created_at)
ORDER BY hour_created;



-- Function to get system health summary

CREATE OR REPLACE FUNCTION get_system_health_summary()
RETURNS TABLE (
    metric_name STRING,
    metric_value STRING,
    status STRING
)
LANGUAGE SQL
AS
$$
    WITH metrics AS (
        SELECT 
            'Total Active Incidents' as name,
            COUNT(*)::STRING as value,
            CASE 
                WHEN COUNT(*) > 50 THEN 'critical'
                WHEN COUNT(*) > 20 THEN 'warning'
                ELSE 'ok'
            END as status
        FROM incidents 
        WHERE status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor')
        
        UNION ALL
        
        SELECT 
            'Critical Priority Incidents',
            COUNT(*)::STRING,
            CASE 
                WHEN COUNT(*) > 5 THEN 'critical'
                WHEN COUNT(*) > 2 THEN 'warning'
                ELSE 'ok'
            END
        FROM incidents 
        WHERE priority = 'critical' 
        AND status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor')
        
        UNION ALL
        
        SELECT 
            'Overdue Incidents',
            COUNT(*)::STRING,
            CASE 
                WHEN COUNT(*) > 10 THEN 'critical'
                WHEN COUNT(*) > 3 THEN 'warning'
                ELSE 'ok'
            END
        FROM incidents 
        WHERE is_incident_overdue(status, sla_due_at) = true
        
        UNION ALL
        
        SELECT 
            'Avg Resolution Time (Hours) - Last 7 Days',
            ROUND(
                AVG(DATEDIFF('hour', created_at, resolved_at)), 2
            )::STRING,
            CASE 
                WHEN AVG(DATEDIFF('hour', created_at, resolved_at)) > 24 THEN 'warning'
                WHEN AVG(DATEDIFF('hour', created_at, resolved_at)) > 48 THEN 'critical'
                ELSE 'ok'
            END
        FROM incidents 
        WHERE resolved_at IS NOT NULL 
        AND created_at >= DATEADD('day', -7, CURRENT_DATE())
        
        UNION ALL
        
        SELECT 
            'SLA Compliance % - Last 30 Days',
            ROUND(
                (COUNT(CASE WHEN sla_breach = false THEN 1 END)::DECIMAL / COUNT(*)) * 100, 1
            )::STRING || '%',
            CASE 
                WHEN (COUNT(CASE WHEN sla_breach = false THEN 1 END)::DECIMAL / COUNT(*)) < 0.85 THEN 'critical'
                WHEN (COUNT(CASE WHEN sla_breach = false THEN 1 END)::DECIMAL / COUNT(*)) < 0.95 THEN 'warning'
                ELSE 'ok'
            END
        FROM incidents 
        WHERE created_at >= DATEADD('day', -30, CURRENT_DATE())
        AND resolved_at IS NOT NULL
    )
    SELECT name, value, status FROM metrics
$$;