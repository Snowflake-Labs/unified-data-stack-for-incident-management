{{
  config(
    materialized='table'  
    ,description='Closed incidents with resolution metrics, SLA compliance analysis, and performance insights'
    ,tags=['daily']
  )
}}

SELECT 
    i.incident_number,
    i.title,
    i.category,
    i.priority,
    i.status,
    i.assignee_id,
    i.reportee_id,
    
    -- Timeline fields (only available DDL fields)
    i.created_at,
    i.closed_at,
    i.updated_at,
    
    -- System information
    i.source_system,
    i.external_source_id,
    i.has_attachments,
    
    -- Resolution metrics (simplified)
    DATEDIFF('minute', i.created_at, i.closed_at) / 60.0 AS total_resolution_hours,
    
    -- Month/Year for trending
    DATE_TRUNC('month', i.closed_at) AS closed_month,
    EXTRACT(year FROM i.closed_at) AS closed_year,
    EXTRACT(quarter FROM i.closed_at) AS closed_quarter

FROM {{ ref('incidents') }} i
WHERE LOWER(i.status) IN ('closed', 'resolved') AND i.closed_at IS NOT NULL
