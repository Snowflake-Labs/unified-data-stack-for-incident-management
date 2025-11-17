

with 
documents_raw_extracts as(
    select
        * exclude (METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID) ,
        AI_PARSE_DOCUMENT (
            TO_FILE('@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS',relative_path),
             {
                'mode': 'LAYOUT'
                ,'page_split': True
             }
        ) as raw_extracts
        FROM v1_incident_management.bronze_zone.v_qualify_new_documents
        WHERE lower(doc_type) = 'full'
),
documents_chunked_extracts as
(
    select 
    og1.* exclude (raw_extracts),
    SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER(
        lf1.value:content::STRING,
        OBJECT_CONSTRUCT('#', 'header_1', '##', 'header_2'),
        500,
        5
    ) as page_chunks,
    lf1.index::int as page_num
    from documents_raw_extracts og1,
    LATERAL FLATTEN(input => raw_extracts:pages) lf1
)

select 
    og2.* exclude (page_chunks), 
    lf2.value['chunk']::varchar as chunk,
    lf2.value['headers']::object as headers
from documents_chunked_extracts og2,
lateral flatten(input => page_chunks) lf2