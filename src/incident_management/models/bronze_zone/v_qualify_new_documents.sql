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
    end as analysis_type
from {{ source('bronze_zone', 'documents_stream') }}
WHERE relative_path is not null
and contains(relative_path, '{{ var("supported_doc_formats") | join("|") }}')
and size > 0
