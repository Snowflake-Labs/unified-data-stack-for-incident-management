-- Test: High impact incidents view data quality and business logic
-- Tests for the curated_zone high_impact_incidents table

-- Test 1: Ensure only high impact incidents are included (critical/high priority OR high customer/revenue impact)
select 'test_high_impact_criteria_met' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where priority not in ('critical', 'high')
      and coalesce(affected_customers_count, 0) <= 10
      and coalesce(estimated_revenue_impact, 0) <= 1000
) > 0

union all

-- Test 2: Ensure business impact score calculation is reasonable
select 'test_high_impact_business_score_reasonable' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where business_impact_score < 0 or business_impact_score > 10000 -- Reasonable upper bound
) > 0

union all

-- Test 3: Ensure time_hours calculation is non-negative
select 'test_high_impact_time_hours_non_negative' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where time_hours < 0
) > 0

union all

-- Test 4: Ensure affected_customers_count is non-negative
select 'test_high_impact_non_negative_customers' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where affected_customers_count < 0
) > 0

union all

-- Test 5: Ensure estimated_revenue_impact is non-negative
select 'test_high_impact_non_negative_revenue' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where estimated_revenue_impact < 0
) > 0

union all

-- Test 6: Ensure incident_number is populated
select 'test_high_impact_incident_number_populated' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where incident_number is null or trim(incident_number) = ''
) > 0

union all

-- Test 7: Ensure title is populated
select 'test_high_impact_title_populated' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where title is null or trim(title) = ''
) > 0

union all

-- Test 8: Ensure closed_at is after resolved_at when both are populated
select 'test_high_impact_closed_after_resolved' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where closed_at is not null 
      and resolved_at is not null 
      and closed_at <= resolved_at
) > 0

union all

-- Test 9: Ensure acknowledged_at is after created_at when populated
select 'test_high_impact_acknowledged_after_created' as test_name
where (
    select count(*)
    from {{ ref('high_impact_incidents') }}
    where acknowledged_at is not null 
      and acknowledged_at <= created_at
) > 0
