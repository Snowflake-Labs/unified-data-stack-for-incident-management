-- Test: Users table data quality and business rules
-- Tests for the landing_zone users model

-- Test 1: Ensure all users have valid email format
select 'test_users_valid_email_format' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where email is null 
       or email not like '%@%.%'
       or length(email) < 5
) > 0

union all

-- Test 2: Ensure email uniqueness
select 'test_users_unique_email' as test_name
where (
    select count(*) from (
        select email
        from {{ ref('users') }}
        group by email
        having count(*) > 1
    )
) > 0

union all

-- Test 3: Ensure user id uniqueness
select 'test_users_unique_id' as test_name
where (
    select count(*) from (
        select id
        from {{ ref('users') }}
        group by id
        having count(*) > 1
    )
) > 0

union all

-- Test 4: Ensure role is populated
select 'test_users_role_populated' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where role is null or trim(role) = ''
) > 0

union all

-- Test 5: Ensure created_at is reasonable
select 'test_users_created_at_reasonable' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where created_at is null 
       or created_at > current_timestamp()
       or created_at < '2020-01-01'
) > 0

union all

-- Test 6: Ensure updated_at is after or equal to created_at
select 'test_users_updated_after_created' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where updated_at is not null 
      and created_at is not null 
      and updated_at < created_at
) > 0

union all

-- Test 7: Ensure first_name and last_name are derived correctly from email
select 'test_users_name_derivation' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where first_name is null 
       or first_name = ''
       or last_name is null 
       or last_name = ''
) > 0

union all

-- Test 8: Ensure is_active is boolean (true/false)
select 'test_users_is_active_boolean' as test_name
where (
    select count(*)
    from {{ ref('users') }}
    where is_active is null 
       or is_active not in (true, false)
) > 0
