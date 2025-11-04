import snowflake.snowpark.functions as F
from snowflake.snowpark import Session
import json

def get_response_format(relative_path: str):
    asset_path = dbt.config.get("asset_path")
    with open(f'{asset_path}/{relative_path}.json', 'r') as f:
        response_format = json.load(f)
    return response_format

def model(dbt, session: Session):
    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
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
            F.call_builtin('TO_FILE', F.lit('{{ var("docs_stage_path") }}/qa'), F.col('relative_path')),
            get_response_format(F.col('relative_path'))
        )
    )
    
    return document_all_pages
