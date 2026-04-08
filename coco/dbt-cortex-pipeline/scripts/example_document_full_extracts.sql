-- models/gold_zone/document_full_extracts.sql
-- Gold-layer model: AI_PARSE_DOCUMENT + SPLIT_TEXT_MARKDOWN_HEADER chunking
-- This model parses staged documents page-by-page and splits them into
-- searchable chunks for Cortex Search.
{{
    config(
        materialized='incremental',
        description='Document text split into searchable chunks',
        tags=['document_processing']
    )
}}

WITH documents_raw_extracts AS (
    SELECT
        * EXCLUDE (METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID),
        AI_PARSE_DOCUMENT(
            TO_FILE('{{ var("docs_stage_path") }}', relative_path),
            {
                'mode': '{{ var("parse_mode") }}',
                'page_split': {{ var("page_split") }}
            }
        ) AS raw_extracts
    FROM {{ ref('v_qualify_new_documents') }}
    WHERE LOWER(doc_type) = 'full'
),

documents_chunked_extracts AS (
    SELECT
        og.* EXCLUDE (raw_extracts),
        SNOWFLAKE.CORTEX.SPLIT_TEXT_MARKDOWN_HEADER(
            page.value:content::STRING,
            OBJECT_CONSTRUCT('#', 'header_1', '##', 'header_2'),
            {{ var('max_chunk_size') }},
            {{ var('max_chunk_depth') }}
        ) AS page_chunks,
        page.index::INT AS page_num
    FROM documents_raw_extracts og,
    LATERAL FLATTEN(input => raw_extracts:pages) page
)

SELECT
    og.* EXCLUDE (page_chunks),
    chunk.value['chunk']::VARCHAR AS chunk,
    chunk.value['headers']::OBJECT AS headers
FROM documents_chunked_extracts og,
LATERAL FLATTEN(input => page_chunks) chunk
