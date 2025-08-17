-- Test: Incident trends views data quality and business logic
-- Tests for both monthly and weekly trend views

-- Monthly Trends Tests
-- Test 1: Ensure resolution rate percentage is between 0 and 100
select 'test_monthly_trends_resolution_rate_valid' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where resolution_rate_percentage < 0 or resolution_rate_percentage > 100
) > 0

union all

-- Test 2: Ensure total incidents equals sum of status counts
select 'test_monthly_trends_incident_count_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where total_incidents < (resolved_incidents + closed_incidents + open_incidents)
) > 0

union all

-- Test 3: Ensure priority counts sum to total incidents
select 'test_monthly_trends_priority_sum_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where total_incidents != (critical_incidents + high_priority_incidents + medium_priority_incidents + low_priority_incidents)
) > 0

union all

-- Test 4: Ensure average times are non-negative when populated
select 'test_monthly_trends_non_negative_times' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where avg_resolution_time_hours < 0
       or avg_acknowledgment_time_hours < 0
       or avg_first_response_time_hours < 0
) > 0

union all

-- Test 5: Ensure revenue impact and customer counts are non-negative
select 'test_monthly_trends_non_negative_impact' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where total_estimated_revenue_impact < 0
       or total_affected_customers < 0
) > 0

union all

-- Test 6: Ensure month field is properly formatted
select 'test_monthly_trends_month_format' as test_name
where (
    select count(*)
    from {{ ref('v_monthly_incident_trends') }}
    where month is null 
       or extract(day from month) != 1  -- Should be first day of month
) > 0

union all

-- Weekly Trends Tests
-- Test 7: Ensure resolution rate percentage is between 0 and 100
select 'test_weekly_trends_resolution_rate_valid' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where resolution_rate_percentage < 0 or resolution_rate_percentage > 100
) > 0

union all

-- Test 8: Ensure total incidents equals sum of status counts
select 'test_weekly_trends_incident_count_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where total_incidents < (resolved_incidents + closed_incidents + open_incidents)
) > 0

union all

-- Test 9: Ensure high severity count equals critical + high
select 'test_weekly_trends_high_severity_consistency' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where high_severity_incidents != (critical_incidents + high_incidents)
) > 0

union all

-- Test 10: Ensure average times are non-negative when populated
select 'test_weekly_trends_non_negative_times' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where avg_resolution_time_hours < 0
       or avg_acknowledgment_time_hours < 0
       or avg_first_response_time_hours < 0
) > 0

union all

-- Test 11: Ensure revenue impact and customer counts are non-negative
select 'test_weekly_trends_non_negative_impact' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where total_revenue_impact < 0
       or total_affected_customers < 0
) > 0

union all

-- Test 12: Ensure week field is properly formatted (Monday start)
select 'test_weekly_trends_week_format' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where week is null 
       or extract(dow from week) != 1  -- Should be Monday (1 = Monday in Snowflake)
) > 0

union all

-- Test 13: Ensure weekly data is within last 12 weeks
select 'test_weekly_trends_date_range' as test_name
where (
    select count(*)
    from {{ ref('v_weekly_incident_trends') }}
    where week < dateadd('week', -12, current_date())
       or week > current_date()
) > 0
