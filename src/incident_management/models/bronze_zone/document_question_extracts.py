import snowflake.snowpark.functions as F
from snowflake.snowpark import Session
import json

def get_response_format(asset_path: str, relative_path: str):
    with open(f'global_inm_policy_schema.json', 'r') as f:
        response_format = json.load(f)
    return response_format

def model(dbt, session: Session):
    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
    asset_path = dbt.config.get("asset-paths")
    docs_stage = dbt.config.get("docs_stage_path")
    
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
            get_response_format(asset_path, F.col('relative_path'))
        )
    )
    
    return document_all_pages
