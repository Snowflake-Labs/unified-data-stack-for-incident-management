-- Test: Active incidents view data quality and business logic
-- Tests for the curated_zone v_active_incidents view

-- Test 1: Ensure only open incidents are included
select 'test_active_incidents_only_open_status' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where status != 'open'
) > 0

union all

-- Test 2: Ensure SLA status logic is correct
select 'test_active_incidents_sla_status_logic' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where (sla_due_at is not null and sla_due_at < current_timestamp() and sla_status != 'OVERDUE')
       or (sla_due_at is not null and sla_due_at >= current_timestamp() 
           and sla_due_at < dateadd('hour', 2, current_timestamp()) and sla_status != 'DUE_SOON')
       or (sla_due_at is null and sla_status != 'ON_TRACK')
) > 0

union all

-- Test 3: Ensure age_hours calculation is reasonable
select 'test_active_incidents_age_hours_reasonable' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where age_hours < 0 or age_hours > 8760 -- More than a year seems unreasonable for active incidents
) > 0

union all

-- Test 4: Ensure affected_customers_count is non-negative
select 'test_active_incidents_non_negative_customers' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where affected_customers_count < 0
) > 0

union all

-- Test 5: Ensure estimated_revenue_impact is non-negative
select 'test_active_incidents_non_negative_revenue' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where estimated_revenue_impact < 0
) > 0

union all

-- Test 6: Ensure incident_number is populated
select 'test_active_incidents_incident_number_populated' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where incident_number is null or trim(incident_number) = ''
) > 0

union all

-- Test 7: Ensure title is populated
select 'test_active_incidents_title_populated' as test_name
where (
    select count(*)
    from {{ ref('v_active_incidents') }}
    where title is null or trim(title) = ''
) > 0
