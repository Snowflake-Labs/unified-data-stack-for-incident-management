import snowflake.snowpark.functions as F
from snowflake.snowpark import Session
import json


def model(dbt, session: Session):
    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
    docs_stage = dbt.config.get("docs_stage_path")
    global_inm_policy_schema = dbt.config.get("global_inm_policy_schema") 

    # Get the upstream model
    v_qualify_new_documents = dbt.ref('v_qualify_new_documents')
    
    # Filter for question analysis type
    document_all_pages = v_qualify_new_documents.filter(
        F.col('analysis_type') == 'question'
    )
    
    # Add AI_EXTRACT column
    # Note: AI_EXTRACT with TO_FILE and response_format needs to be done via SQL expression
    document_all_pages = document_all_pages.with_column(
        'question_extracts_json',
        F.call_builtin(
            'AI_EXTRACT',
            F.call_builtin('TO_FILE', F.lit(f'{docs_stage}'), F.col('relative_path')),
            json.dumps(global_inm_policy_schema)
        )
    )
    
    return document_all_pages
