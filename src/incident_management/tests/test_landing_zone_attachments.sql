-- Test: Incident attachments data quality and business rules
-- Tests for the landing_zone incident_attachments model

-- Test 1: Ensure all attachments have valid incident references
select 'test_attachments_valid_incident_ref' as test_name
where (
    select count(*)
    from {{ ref('incident_attachments') }} a
    left join {{ ref('incidents') }} i on a.incident_number = i.incident_number
    where i.incident_number is null
) > 0

union all

-- Test 2: Ensure uploaded_at is reasonable
select 'test_attachments_uploaded_at_reasonable' as test_name
where (
    select count(*)
    from {{ ref('incident_attachments') }}
    where uploaded_at is null 
       or uploaded_at > current_timestamp()
       or uploaded_at < '2020-01-01'
) > 0

union all

-- Test 3: Ensure attachment uploaded_at is after incident created_at
select 'test_attachments_after_incident_created' as test_name
where (
    select count(*)
    from {{ ref('incident_attachments') }} a
    join {{ ref('incidents') }} i on a.incident_number = i.incident_number
    where a.uploaded_at < i.created_at
) > 0

union all

-- Test 4: Ensure unique ID for each attachment
select 'test_attachments_unique_id' as test_name
where (
    select count(*) from (
        select id
        from {{ ref('incident_attachments') }}
        group by id
        having count(*) > 1
    )
) > 0

union all

-- Test 5: Ensure incidents with attachments have has_attachments flag set
select 'test_incidents_attachment_flag_consistency' as test_name
where (
    select count(*)
    from {{ ref('incidents') }} i
    left join (
        select incident_number, count(*) as attachment_count
        from {{ ref('incident_attachments') }}
        group by incident_number
    ) a on i.incident_number = a.incident_number
    where (a.attachment_count > 0 and i.has_attachments = false)
       or (a.attachment_count is null and i.has_attachments = true)
) > 0
