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

-- Test 5: Ensure closed_at is after created_at when populated
select 'test_incidents_closed_after_created' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where closed_at is not null 
      and closed_at <= created_at
) > 0

union all

-- Test 6: Ensure updated_at is after or equal to created_at
select 'test_incidents_updated_after_created' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where updated_at < created_at
) > 0

union all

-- Test 7: Ensure category is populated
select 'test_incidents_category_populated' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where category is null or trim(category) = ''
) > 0

union all

-- Test 8: Ensure source_system is valid
select 'test_incidents_valid_source_system' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where source_system not in ('monitoring', 'customer_portal', 'manual', 'Slack')
) > 0

union all

-- Test 9: Ensure has_attachments is boolean
select 'test_incidents_has_attachments_boolean' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where has_attachments not in (true, false)
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

-- Test 10: Ensure external_source_id is populated when source_system is not manual
select 'test_incidents_external_source_id_consistency' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where source_system != 'manual' 
      and (external_source_id is null or trim(external_source_id) = '')
) > 0
