-- Test: Active incidents view data quality and business logic
-- Tests for the curated_zone active_incidents table

-- Test 1: Ensure only open incidents are included
select 'test_active_incidents_only_open_status' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where status != 'open'
) > 0

union all

-- Test 2: Ensure age_hours calculation is reasonable
select 'test_active_incidents_age_hours_reasonable' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where age_hours < 0 or age_hours > 8760 -- More than a year seems unreasonable for active incidents
) > 0

union all

-- Test 3: Ensure category is populated
select 'test_active_incidents_category_populated' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where category is null or trim(category) = ''
) > 0

union all

-- Test 4: Ensure priority is valid
select 'test_active_incidents_valid_priority' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where priority not in ('low', 'medium', 'high', 'critical')
) > 0

union all

-- Test 5: Ensure source_system is populated
select 'test_active_incidents_source_system_populated' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where source_system is null or trim(source_system) = ''
) > 0

union all

-- Test 6: Ensure incident_number is populated
select 'test_active_incidents_incident_number_populated' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where incident_number is null or trim(incident_number) = ''
) > 0

union all

-- Test 7: Ensure title is populated
select 'test_active_incidents_title_populated' as test_name
where (
    select count(*)
    from {{ ref('active_incidents') }}
    where title is null or trim(title) = ''
) > 0
