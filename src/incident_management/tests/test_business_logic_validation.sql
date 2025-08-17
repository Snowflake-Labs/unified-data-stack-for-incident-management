-- Test: Business logic and process validation
-- Tests that validate business rules and incident management processes

-- Test 1: Ensure SLA due dates are reasonable based on priority
select 'test_business_sla_due_date_logic' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'open'
      and sla_due_at is not null
      and (
          (priority = 'critical' and datediff('hour', created_at, sla_due_at) > 4)
          or (priority = 'high' and datediff('hour', created_at, sla_due_at) > 8)
          or (priority = 'medium' and datediff('day', created_at, sla_due_at) > 3)
          or (priority = 'low' and datediff('day', created_at, sla_due_at) > 7)
      )
) > 0

union all

-- Test 2: Ensure incidents can't be resolved without being acknowledged first (business rule)
select 'test_business_resolved_requires_acknowledgment' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status in ('resolved', 'closed')
      and acknowledged_at is null
      and resolved_at is not null
) > 0

union all

-- Test 3: Ensure high priority incidents have reasonable response times
select 'test_business_critical_incident_response_time' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where priority = 'critical'
      and first_response_at is not null
      and datediff('hour', created_at, first_response_at) > 2  -- Critical incidents should get response within 2 hours
) > 0

union all

-- Test 4: Ensure incidents with high customer impact have appropriate priority
select 'test_business_customer_impact_priority_alignment' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where affected_customers_count > 100
      and priority not in ('critical', 'high')
) > 0

union all

-- Test 5: Ensure incidents with high revenue impact have appropriate priority
select 'test_business_revenue_impact_priority_alignment' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where estimated_revenue_impact > 5000
      and priority not in ('critical', 'high')
) > 0

union all

-- Test 6: Ensure resolved incidents have resolution summary (business requirement)
select 'test_business_resolved_has_summary' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status in ('resolved', 'closed')
      and (resolution_summary is null or trim(resolution_summary) = '')
) > 0

union all

-- Test 7: Ensure closed incidents were resolved first (process validation)
select 'test_business_closed_was_resolved_first' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'closed'
      and (resolved_at is null or closed_at <= resolved_at)
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

-- Test 9: Ensure active incidents don't have resolution details
select 'test_business_active_no_resolution_details' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where status = 'open'
      and (resolution_summary is not null and trim(resolution_summary) != '')
) > 0

union all

-- Test 10: Ensure SLA breach flag is set correctly for overdue incidents
select 'test_business_sla_breach_flag_accuracy' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where sla_due_at is not null
      and sla_due_at < current_timestamp()
      and status = 'open'
      and sla_breach = false
) > 0

union all

-- Test 11: Ensure incident progression follows logical timeline
select 'test_business_incident_timeline_logic' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where (acknowledged_at is not null and acknowledged_at < created_at)
       or (first_response_at is not null and first_response_at < created_at)
       or (resolved_at is not null and resolved_at < created_at)
       or (closed_at is not null and closed_at < created_at)
       or (first_response_at is not null and acknowledged_at is not null and first_response_at < acknowledged_at)
) > 0

union all

-- Test 12: Ensure comment timestamps align with incident lifecycle
select 'test_business_comment_timeline_logic' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    join {{ ref('incidents') }} i on ch.incident_number = i.incident_number
    where ch.created_at < i.created_at
       or (i.closed_at is not null and ch.created_at > dateadd('day', 1, i.closed_at))  -- Comments shouldn't come too long after closure
) > 0

union all

-- Test 13: Ensure category classification is reasonable for incident content
select 'test_business_category_classification_coverage' as test_name
where (
    select count(*)
    from {{ ref('incidents') }}
    where category is null or trim(category) = '' or category = 'other'
) > (
    select count(*) from {{ ref('incidents') }}
) * 0.3  -- No more than 30% should be uncategorized or "other"

union all

-- Test 14: Ensure incident distribution across priorities is reasonable
select 'test_business_priority_distribution' as test_name
where (
    select count(*) from {{ ref('incidents') }} where priority = 'critical'
) > (
    select count(*) from {{ ref('incidents') }}
) * 0.1  -- Critical incidents should be less than 10% of total
