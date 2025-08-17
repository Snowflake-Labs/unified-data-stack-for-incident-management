{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='email',
        description='Materialized users table with enriched data'
    )
}}

select 
    uuid_string() as id,
    sm.memberemails[0] as email,
    split(sm.memberemails[0], '@')[0] as first_name,
    split(sm.memberemails[0], '@')[1] as last_name,
    'reporter' as role,
    '' as department,
    '' as team,
    true as is_active,
    sm.lastupdated as created_at,
    current_timestamp() as updated_at
from {{ source('landing_zone', 'slack_members') }} sm 
{% if is_incremental() %}   
where sm.lastupdated > (select max(sm.lastupdated) from {{ this }})
{% endif %}