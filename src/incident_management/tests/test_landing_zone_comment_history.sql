-- Test: Incident comment history data quality and business rules
-- Tests for the landing_zone incident_comment_history model

-- Test 1: Ensure all comments have valid incident references
select 'test_comment_history_valid_incident_ref' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    left join {{ ref('incidents') }} i on ch.incident_number = i.incident_number
    where i.incident_number is null
) > 0

union all

-- Test 2: Ensure all comments have valid author references
select 'test_comment_history_valid_author_ref' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    left join {{ ref('users') }} u on ch.author_id = u.id
    where u.id is null
) > 0

union all

-- Test 3: Ensure comment content is not empty
select 'test_comment_history_content_not_empty' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }}
    where content is null or trim(content) = ''
) > 0

union all

-- Test 4: Ensure created_at is reasonable
select 'test_comment_history_created_at_reasonable' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }}
    where created_at is null 
       or created_at > current_timestamp()
       or created_at < '2020-01-01'
) > 0

union all

-- Test 5: Ensure comment created_at is after incident created_at
select 'test_comment_history_after_incident_created' as test_name
where (
    select count(*)
    from {{ ref('incident_comment_history') }} ch
    join {{ ref('incidents') }} i on ch.incident_number = i.incident_number
    where ch.created_at < i.created_at
) > 0

union all

-- Test 6: Ensure unique ID for each comment
select 'test_comment_history_unique_id' as test_name
where (
    select count(*) from (
        select id
        from {{ ref('incident_comment_history') }}
        group by id
        having count(*) > 1
    )
) > 0
