{{
    config(
        materialized='view',
        description='Dummy table for document extracts (schema placeholder)'
    )
}}

select
   *,
    case 
        when contains(relative_path, 'qa') then 'question'
        when contains(relative_path, 'full') then 'full'
        else 'full'
    end as analysis_type,
    split_part(relative_path, '.', 2) as extension
from {{ source('bronze_zone', 'documents_stream') }}
WHERE relative_path is not null
and array_contains(extension::VARIANT, {{ var("supported_doc_formats") }} )
and size > 0