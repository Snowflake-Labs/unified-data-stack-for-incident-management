-- Test: Category performance view data quality and business logic
-- Tests for the curated_zone v_category_performance view

-- Test 1: Ensure resolution rate percentage is between 0 and 100
select 'test_category_performance_resolution_rate_valid' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where resolution_rate_percentage < 0 or resolution_rate_percentage > 100
) > 0

union all

-- Test 2: Ensure total incidents equals sum of resolved and unresolved
select 'test_category_performance_incident_count_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where total_incidents < resolved_incidents
) > 0

union all

-- Test 3: Ensure average resolution time is non-negative when populated
select 'test_category_performance_non_negative_resolution_time' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where avg_resolution_time_hours < 0
) > 0

union all

-- Test 4: Ensure average acknowledgment time is non-negative when populated
select 'test_category_performance_non_negative_ack_time' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where avg_acknowledgment_time_hours < 0
) > 0

union all

-- Test 5: Ensure average first response time is non-negative when populated
select 'test_category_performance_non_negative_response_time' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where avg_first_response_time_hours < 0
) > 0

union all

-- Test 6: Ensure priority counts sum to total incidents
select 'test_category_performance_priority_sum_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where total_incidents != (critical_incidents + high_incidents + medium_incidents + low_incidents)
) > 0

union all

-- Test 7: Ensure total revenue impact is non-negative
select 'test_category_performance_non_negative_revenue' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where total_revenue_impact < 0
) > 0

union all

-- Test 8: Ensure total affected customers is non-negative
select 'test_category_performance_non_negative_customers' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where total_affected_customers < 0
) > 0

union all

-- Test 9: Ensure category name is populated
select 'test_category_performance_category_populated' as test_name
where (
    select count(*)
    from {{ ref('v_category_performance') }}
    where category_name is null or trim(category_name) = ''
) > 0
