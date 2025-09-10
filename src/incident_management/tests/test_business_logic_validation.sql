-- Test: Business logic and process validation
-- Tests that validate business rules and incident management processes

-- Test 1: Ensure category classification is reasonable for incident content
select 'test_business_category_classification_coverage' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where category is null or trim(category) = '' or category = 'other'
) > (
    select count(*) from {{ ref('incidents') }}
) * 0.3  -- No more than 30% should be uncategorized or "other"

union all

-- Test 2: Ensure incident distribution across priorities is reasonable
select 'test_business_priority_distribution' as test_name
where (
    select count(*) from {{ ref('incidents') }} where priority = 'critical'
) > (
    select count(*) from {{ ref('incidents') }}
) * 0.1  -- Critical incidents should be less than 10% of total

union all

-- Test 3: Ensure closed incidents have closed_at timestamp
select 'test_business_closed_status_has_timestamp' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'closed'
      and closed_at is null
) > 0

union all

-- Test 4: Ensure open incidents don't have closed_at timestamp
select 'test_business_open_no_closed_timestamp' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'open'
      and closed_at is not null
) > 0

union all

-- Test 5: Ensure reasonable incident age for open incidents
select 'test_business_open_incident_age_reasonable' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'open'
      and datediff('day', created_at, current_timestamp()) > 90  -- Open incidents older than 90 days seem unreasonable
) > 0

union all

-- Test 8: Ensure incidents with attachments have the flag set correctly
select 'test_business_attachment_flag_accuracy' as test_name
where (
    select count(*)
    from {{ ref('incidents') }} i
    left join (
        select incident_number, count(*) as attachment_count
        from {{ ref('incident_attachments') }}
        group by incident_number
    ) a on i.incident_number = a.incident_number
    where (coalesce(a.attachment_count, 0) > 0 and i.has_attachments = false)
       or (coalesce(a.attachment_count, 0) = 0 and i.has_attachments = true)
) > 0

union all

-- Test 6: Ensure comment timestamps align with incident lifecycle
select 'test_business_comment_timeline_logic' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    join {{ ref('incidents') }} i on ch.incident_number = i.incident_number
    where ch.created_at < i.created_at
       or (i.closed_at is not null and ch.created_at > dateadd('day', 1, i.closed_at))  -- Comments shouldn't come too long after closure
) > 0

union all

-- Test 7: Ensure source system consistency
select 'test_business_source_system_consistency' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where source_system = 'Slack' 
      and (external_source_id is null or trim(external_source_id) = '')
) > 0

union all

-- Test 8: Ensure updated_at reflects actual updates
select 'test_business_updated_at_logic' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'closed'
      and updated_at < closed_at
) > 0
