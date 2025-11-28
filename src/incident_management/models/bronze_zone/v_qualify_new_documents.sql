{{
    config(
        materialized='view'
        , description='View to qualify new documents that could be staged under the designated location'
        , tags=['document_processing']
    )
}}

select
   *,
    case 
        when contains(relative_path, 'qa') then 'question'
        when contains(relative_path, 'full') then 'full'
        else 'slack'
    end as doc_type,
    split_part(relative_path, '.', 2) as extension
from {{ source('bronze_zone', 'documents_stream') }}
WHERE METADATA$ACTION != 'DELETE'
and relative_path is not null
and array_contains(extension::VARIANT, {{ var("supported_doc_formats") }} )
and size > 0