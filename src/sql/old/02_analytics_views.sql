-- Analytics Views for Incident Management System - Snowflake Version
-- Optimized for reporting and data mining

-- =============================================
-- INCIDENT OVERVIEW AND METRICS
-- =============================================

-- Comprehensive incident overview with calculated metrics
CREATE OR REPLACE VIEW v_incident_overview AS
SELECT 
    i.id,
    i.incident_number,
    i.title,
    i.status,
    i.category,
    i.priority,
    ic.name AS category_name,
    
    -- People
    CONCAT(reporter.first_name, ' ', reporter.last_name) AS reporter_name,
    reporter.role AS reporter_role,
    reporter.department AS reporter_department,
    CONCAT(assignee.first_name, ' ', assignee.last_name) AS assignee_name,
    assignee.role AS assignee_role,
    assignee.team AS assignee_team,
    
    -- Business impact
    i.affected_customers_count,
    i.estimated_revenue_impact,
    
    -- Timing metrics
    i.created_at,
    i.acknowledged_at,
    i.first_response_at,
    i.resolved_at,
    i.closed_at,
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
        WHEN i.status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor')
        THEN DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP())
        ELSE NULL 
    END AS current_age_hours,
    
    -- Resolution details
    i.resolution_summary,
    i.root_cause,
    i.resolution_category,
    i.source_system
FROM incidents i
LEFT JOIN users reporter ON i.reporter_id = reporter.id
LEFT JOIN users assignee ON i.assignee_id = assignee.id;

-- =============================================
-- TIME-BASED ANALYTICS
-- =============================================

-- Monthly incident trends
CREATE OR REPLACE VIEW v_monthly_incident_trends AS
SELECT 
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) AS resolved_incidents,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) AS closed_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) AS high_priority_incidents,
    COUNT(CASE WHEN sla_breach = true THEN 1 END) AS sla_breaches,
    
    -- Average resolution time for resolved incidents (in hours)
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    
    -- Total estimated revenue impact
    SUM(COALESCE(estimated_revenue_impact, 0)) AS total_estimated_revenue_impact,
    
    -- Total affected customers
    SUM(affected_customers_count) AS total_affected_customers
    
FROM incidents
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- Weekly incident trends (last 12 weeks)
CREATE OR REPLACE VIEW v_weekly_incident_trends AS
SELECT 
    DATE_TRUNC('week', created_at) AS week,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END) AS resolved_incidents,
    COUNT(CASE WHEN priority IN ('critical', 'high') THEN 1 END) AS high_severity_incidents,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours
FROM incidents
WHERE created_at >= DATEADD('week', -12, CURRENT_DATE())
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY week DESC;

-- =============================================
-- PERFORMANCE ANALYTICS
-- =============================================

-- Team performance metrics
CREATE OR REPLACE VIEW v_team_performance AS
SELECT 
    u.team,
    u.department,
    COUNT(*) AS total_assigned_incidents,
    COUNT(CASE WHEN i.status IN ('resolved', 'closed') THEN 1 END) AS resolved_incidents,
    ROUND(
        (COUNT(CASE WHEN i.status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage,
    
    -- Average resolution time
    AVG(
        CASE 
            WHEN i.resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', i.created_at, i.resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    
    -- SLA performance
    COUNT(CASE WHEN i.sla_breach = true THEN 1 END) AS sla_breaches,
    ROUND(
        (COUNT(CASE WHEN i.sla_breach = true THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS sla_breach_percentage,
    
    -- Current workload (open incidents)
    COUNT(CASE WHEN i.status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor') THEN 1 END) AS current_open_incidents

FROM incidents i
JOIN users u ON i.assignee_id = u.id
WHERE u.team IS NOT NULL
GROUP BY u.team, u.department
ORDER BY total_assigned_incidents DESC;

-- =============================================
-- BUSINESS IMPACT ANALYTICS
-- =============================================

-- High-impact incidents analysis
CREATE OR REPLACE VIEW v_high_impact_incidents AS
SELECT 
    i.id,
    i.incident_number,
    i.title,
    i.status,
    i.priority,
    ic.name AS category_name,
    i.affected_customers_count,
    i.estimated_revenue_impact,
    i.created_at,
    i.resolved_at,
    
    -- Time to resolution
    CASE 
        WHEN i.resolved_at IS NOT NULL 
        THEN DATEDIFF('hour', i.created_at, i.resolved_at)
        ELSE DATEDIFF('hour', i.created_at, CURRENT_TIMESTAMP())
    END AS time_hours,
    
    -- Business impact score (custom calculation)
    calculate_business_impact_score(i.priority, i.affected_customers_count, COALESCE(i.estimated_revenue_impact, 0)) AS business_impact_score

FROM incidents i
LEFT JOIN incident_categories ic ON i.category_id = ic.id
WHERE i.priority IN ('critical', 'high') 
   OR i.affected_customers_count > 10 
   OR i.estimated_revenue_impact > 1000
ORDER BY business_impact_score DESC, i.created_at DESC;

-- Revenue impact by category
CREATE OR REPLACE VIEW v_revenue_impact_by_category AS
SELECT 
    ic.name AS category_name,
    COUNT(*) AS total_incidents,
    SUM(COALESCE(i.estimated_revenue_impact, 0)) AS total_revenue_impact,
    AVG(COALESCE(i.estimated_revenue_impact, 0)) AS avg_revenue_impact_per_incident,
    SUM(i.affected_customers_count) AS total_affected_customers,
    AVG(i.affected_customers_count::DECIMAL) AS avg_affected_customers_per_incident
FROM incidents i
JOIN incident_categories ic ON i.category_id = ic.id
GROUP BY ic.name
ORDER BY total_revenue_impact DESC;

-- =============================================
-- OPERATIONAL ANALYTICS
-- =============================================

-- Incident source analysis
CREATE OR REPLACE VIEW v_incident_sources AS
SELECT 
    COALESCE(source_system, 'Unknown') AS source_system,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END) AS resolved_incidents,
    ROUND(
        (COUNT(CASE WHEN status IN ('resolved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) AS resolution_rate_percentage,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours
FROM incidents
GROUP BY source_system
ORDER BY total_incidents DESC;

-- =============================================
-- REAL-TIME MONITORING VIEWS
-- =============================================

-- Current active incidents dashboard
CREATE OR REPLACE VIEW v_active_incidents_dashboard AS
SELECT 
    i.id,
    i.incident_number,
    i.title,
    i.status,
    i.priority,
    ic.name AS category_name,
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
    i.estimated_revenue_impact
FROM incidents i
LEFT JOIN incident_categories ic ON i.category_id = ic.id
LEFT JOIN users assignee ON i.assignee_id = assignee.id
WHERE i.status IN ('open', 'in_progress', 'pending_customer', 'pending_vendor')
ORDER BY 
    CASE i.priority 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END,
    i.created_at;

-- =============================================
-- SNOWFLAKE-SPECIFIC PERFORMANCE VIEWS
-- =============================================

-- Incident resolution performance by hour of day
CREATE OR REPLACE VIEW v_hourly_performance_patterns AS
SELECT 
    EXTRACT('hour', created_at) AS hour_of_day,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN priority IN ('critical', 'high') THEN 1 END) AS high_priority_incidents,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
            ELSE NULL 
        END
    ) AS avg_resolution_time_hours,
    COUNT(CASE WHEN sla_breach = true THEN 1 END) AS sla_breaches
FROM incidents
WHERE created_at >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY EXTRACT('hour', created_at)
ORDER BY hour_of_day;

-- Incident trends by day of week
CREATE OR REPLACE VIEW v_daily_incident_patterns AS
SELECT 
    DAYOFWEEK(created_at) AS day_of_week,
    CASE DAYOFWEEK(created_at)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS day_name,
    COUNT(*) AS total_incidents,
    COUNT(CASE WHEN priority = 'critical' THEN 1 END) AS critical_incidents,
    AVG(
        CASE 
            WHEN resolved_at IS NOT NULL 
            THEN DATEDIFF('hour', created_at, resolved_at)
        END
    ) AS avg_resolution_hours,
    COUNT(CASE WHEN sla_breach = true THEN 1 END) AS sla_breaches
FROM incidents
WHERE created_at >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY DAYOFWEEK(created_at)
ORDER BY day_of_week;

-- =============================================
-- SIMPLIFIED CATEGORY ANALYTICS
-- =============================================

-- Category performance overview
CREATE OR REPLACE VIEW v_category_performance AS
SELECT 
    ic.name AS category_name,
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
    COUNT(CASE WHEN i.priority = 'critical' THEN 1 END) AS critical_incidents,
    COUNT(CASE WHEN i.sla_breach = true THEN 1 END) AS sla_breaches,
    SUM(COALESCE(i.estimated_revenue_impact, 0)) AS total_revenue_impact
FROM incidents i
LEFT JOIN incident_categories ic ON i.category_id = ic.id
GROUP BY ic.name
ORDER BY total_incidents DESC;