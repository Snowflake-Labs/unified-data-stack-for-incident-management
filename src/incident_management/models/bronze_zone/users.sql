{{
    config(
        materialized='incremental'
        ,incremental_strategy='merge'
        ,unique_key='email'
        ,merge_exclude_columns=['created_at']
        ,description='Materialized users table with enriched data'
        ,tags=['daily']
    )
}}

with _temp as (
 select 
 *, 
 arrays_zip(memberids, memberemails) as zip_data 
 from {{ source('bronze_zone', 'slack_members') }} sm
)
select 
   f.value:$1 as id,
   f.value:$2 as email,
    split(email, '@')[0] as first_name,
    split(email, '@')[1] as last_name,
    'reporter' as role,
    '' as department,
    '' as team,
    true as is_active,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from _temp,
lateral flatten(input => zip_data) f