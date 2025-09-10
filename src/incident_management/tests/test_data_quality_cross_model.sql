-- Test: Cross-model data quality and referential integrity
-- Tests that validate data consistency across multiple models

-- Test 1: Ensure all incidents referenced in comments exist
select 'test_cross_model_comment_incident_ref' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    left join {{ ref('incidents') }} i on ch.incident_number = i.incident_number
    where i.incident_number is null
) > 0

union all

-- Test 2: Ensure all incidents referenced in attachments exist
select 'test_cross_model_attachment_incident_ref' as test_name
where (
    select count(*)
    from {{ ref('incident_attachments') }} a
    left join {{ ref('incidents') }} i on a.incident_number = i.incident_number
    where i.incident_number is null
) > 0

union all

-- Test 3: Ensure all assignee references in incidents are valid
select 'test_cross_model_incident_user_refs' as test_name
where (
    select count(*)
    from {{ ref('incidents') }} i
    left join {{ ref('users') }} assignee on i.assignee_id = assignee.id
    where i.assignee_id is not null and assignee.id is null
) > 0

union all

-- Test 4: Ensure active incidents count consistency
select 'test_cross_model_active_incident_consistency' as test_name
where (
    select abs(
        (select count(*) from {{ ref('incidents') }} where status = 'open') - 
        (select count(*) from {{ ref('active_incidents') }})
    )
) > 0

union all

-- Test 5: Ensure closed incidents count consistency
select 'test_cross_model_closed_incident_consistency' as test_name
where (
    select abs(
        (select count(*) from {{ ref('incidents') }} where status in ('closed', 'resolved')) - 
        (select count(*) from {{ ref('closed_incidents') }})
    )
) > 0

union all

-- Test 7: Ensure comments exist only for incidents that exist
select 'test_cross_model_orphaned_comments' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    where ch.incident_number not in (
        select incident_number from {{ ref('incidents') }}
    )
) > 0

union all

-- Test 8: Ensure attachments exist only for incidents that exist
select 'test_cross_model_orphaned_attachments' as test_name
where (
    select count(*)
    from {{ ref('incident_attachments') }} a
    where a.incident_number not in (
        select incident_number from {{ ref('incidents') }}
    )
) > 0

union all

-- Test 9: Ensure user activity consistency (users with comments/incidents should exist)
select 'test_cross_model_user_activity_consistency' as test_name
where (
    select count(distinct author_id) from {{ ref('incident_comment_history') }}
    where author_id not in (select id from {{ ref('users') }})
) > 0

union all

-- Test 10: Ensure data freshness - no future dates
select 'test_cross_model_no_future_dates' as test_name
where (
    select count(*) from (
        select created_at from {{ ref('incidents') }} where created_at > current_timestamp()
        union all
        select created_at from {{ ref('users') }} where created_at > current_timestamp()
        union all
        select created_at from {{ ref('incident_comment_history') }} where created_at > current_timestamp()
        union all
        select uploaded_at from {{ ref('incident_attachments') }} where uploaded_at > current_timestamp()
    )
) > 0
