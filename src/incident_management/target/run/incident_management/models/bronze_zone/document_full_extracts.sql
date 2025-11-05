
  
    

        create or replace transient table incident_management.bronze_zone.document_full_extracts
         as
        (


with document_all_pages
as
(
    select
        *,
        AI_PARSE_DOCUMENT (
            TO_FILE('@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS/full',relative_path),
            parse_mode => 'LAYOUT', 
            page_split => true
        ) as chunk
        FROM incident_management.bronze_zone.v_qualify_new_documents
        WHERE analysis_type = 'full'
)

select 
*,
f.value:content::STRING as page_content,
f.index::int as page_num
from document_all_pages,
LATERAL FLATTEN(input => chunk:pages) f;
        );
      
  