{{
    config(
        materialized='table',
        description='Dummy table for document extracts (schema placeholder)'
        ,enable=false
    )
}}


with document_all_pages
as
(
    select
        *,
        AI_PARSE_DOCUMENT (
            TO_FILE('{{ var("docs_stage_path") }}/full',relative_path),
            parse_mode => 'LAYOUT', 
            page_split => true
        ) as chunk
        FROM {{ ref('v_qualify_new_documents') }}
        WHERE analysis_type = 'full'
)

select 
*,
f.value:content::STRING as page_content,
f.index::int as page_num
from document_all_pages,
LATERAL FLATTEN(input => chunk:pages) f;
