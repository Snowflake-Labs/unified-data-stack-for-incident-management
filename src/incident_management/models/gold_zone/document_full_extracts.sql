{{
    config(
        materialized='incremental'
        ,description='Table that contains the full extracts from the documents'
        ,tags=['document_processing']
    )
}}

with 
documents_raw_extracts as(
    select
        * exclude (METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID) ,
        AI_PARSE_DOCUMENT (
            TO_FILE('{{ var("docs_stage_path") }}',relative_path),
             {
                'mode': '{{var("parse_mode")}}'
                ,'page_split': {{var("page_split")}}
             }
        ) as raw_extracts
        FROM {{ ref('v_qualify_new_documents') }}
        WHERE lower(doc_type) = 'full'
),
documents_chunked_extracts as
(
    select 
    og1.* exclude (raw_extracts),
    SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER(
        lf1.value:content::STRING,
        OBJECT_CONSTRUCT('#', 'header_1', '##', 'header_2'),
        {{var('max_chunk_size')}},
        {{var('max_chunk_depth')}}
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
