-- Test: Incident overview view data quality and business logic
-- Tests for the curated_zone incident_overview table

-- Test 1: Ensure all time calculations are non-negative when populated
select 'test_incident_overview_non_negative_times' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where acknowledgment_time_hours < 0
       or first_response_time_hours < 0
       or resolution_time_hours < 0
       or total_time_hours < 0
       or current_age_hours < 0
) > 0

union all

-- Test 2: Ensure status_category mapping is correct
select 'test_incident_overview_status_category_mapping' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where (status = 'open' and status_category != 'Active')
       or (status = 'resolved' and status_category != 'Resolved')
       or (status = 'closed' and status_category != 'Closed')
       or (status not in ('open', 'resolved', 'closed') and status_category != 'Unknown')
) > 0

union all

-- Test 3: Ensure priority_score mapping is correct
select 'test_incident_overview_priority_score_mapping' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where (priority = 'critical' and priority_score != 4)
       or (priority = 'high' and priority_score != 3)
       or (priority = 'medium' and priority_score != 2)
       or (priority = 'low' and priority_score != 1)
) > 0

union all

-- Test 4: Ensure risk_indicator logic is correct
select 'test_incident_overview_risk_indicator_logic' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where (sla_breach = true and risk_indicator != 'SLA Breached')
       or (sla_breach = false and status = 'open' and sla_due_at is not null 
           and datediff('hour', current_timestamp(), sla_due_at) <= 2 
           and risk_indicator != 'SLA At Risk')
       or (status = 'open' and datediff('hour', created_at, current_timestamp()) > 24 
           and sla_breach = false and risk_indicator != 'Long Running')
) > 0

union all

-- Test 5: Ensure current_age_hours is only calculated for open incidents
select 'test_incident_overview_current_age_open_only' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where status != 'open' and current_age_hours is not null
) > 0

union all

-- Test 6: Ensure hours_until_sla_breach is only calculated for open incidents with SLA
select 'test_incident_overview_sla_hours_open_only' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where (status != 'open' or sla_due_at is null) and hours_until_sla_breach is not null
) > 0

union all

-- Test 7: Ensure affected_customers_count is non-negative
select 'test_incident_overview_non_negative_customers' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where affected_customers_count < 0
) > 0

union all

-- Test 8: Ensure estimated_revenue_impact is non-negative
select 'test_incident_overview_non_negative_revenue' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where estimated_revenue_impact < 0
) > 0

union all

-- Test 9: Ensure incident_number is populated
select 'test_incident_overview_incident_number_populated' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where incident_number is null or trim(incident_number) = ''
) > 0

union all

-- Test 10: Ensure title is populated
select 'test_incident_overview_title_populated' as test_name
where (
    select count(*)
    from {{ ref('incident_overview') }}
    where title is null or trim(title) = ''
) > 0
