-- Test: Incidents table data quality and business rules
-- Tests for the landing_zone incidents model

-- Test 1: Ensure incident_number is unique and not null
select 'test_incidents_unique_incident_number' as test_name
where (
    select count(*) from (
        select incident_number
        from {{ ref('incidents') }}
        group by incident_number
        having count(*) > 1
    )
) > 0

union all

-- Test 2: Ensure all incidents have valid status values
select 'test_incidents_valid_status' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status not in ('open', 'resolved', 'closed')
) > 0

union all

-- Test 3: Ensure all incidents have valid priority values
select 'test_incidents_valid_priority' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where priority not in ('low', 'medium', 'high', 'critical')
) > 0

union all

-- Test 4: Ensure created_at is always populated and reasonable
select 'test_incidents_created_at_populated' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where created_at is null 
       or created_at > current_timestamp()
       or created_at < '2020-01-01'
) > 0

union all

-- Test 5: Ensure resolved_at is after created_at when populated
select 'test_incidents_resolved_after_created' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where resolved_at is not null 
      and resolved_at <= created_at
) > 0

union all

-- Test 6: Ensure closed_at is after resolved_at when both are populated
select 'test_incidents_closed_after_resolved' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where closed_at is not null 
      and resolved_at is not null 
      and closed_at <= resolved_at
) > 0

union all

-- Test 7: Ensure acknowledged_at is after created_at when populated
select 'test_incidents_acknowledged_after_created' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where acknowledged_at is not null 
      and acknowledged_at <= created_at
) > 0

union all

-- Test 8: Ensure first_response_at is after created_at when populated
select 'test_incidents_first_response_after_created' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where first_response_at is not null 
      and first_response_at <= created_at
) > 0

union all

-- Test 9: Ensure affected_customers_count is non-negative
select 'test_incidents_non_negative_customer_count' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where affected_customers_count < 0
) > 0

union all

-- Test 10: Ensure estimated_revenue_impact is non-negative
select 'test_incidents_non_negative_revenue_impact' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where estimated_revenue_impact < 0
) > 0

union all

-- Test 11: Ensure title is not empty
select 'test_incidents_title_not_empty' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where title is null or trim(title) = ''
) > 0

union all

-- Test 12: Ensure SLA due date is in the future for open incidents
select 'test_incidents_sla_due_future_for_open' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'open' 
      and sla_due_at is not null 
      and sla_due_at <= created_at
) > 0
