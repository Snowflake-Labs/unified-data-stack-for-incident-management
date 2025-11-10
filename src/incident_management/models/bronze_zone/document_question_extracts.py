import snowflake.snowpark.functions as F
from snowflake.snowpark import Session

    
def model(dbt, session: Session):
    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
    docs_stage = dbt.config.get("docs_stage_path")

    all_meta = dbt.config.get("meta")
    # global_inm_policy_schema = dbt.config.get("meta")['global_inm_policy_schema']
    reponse_schema = {
        'schema': {
            'type': 'object',
            'properties': {}
        }
    }
    for key in all_meta.keys():
        if all_meta[key]['enabled']:
            reponse_schema['schema']['properties'][key] = all_meta[key]['schema']['properties']

    # Get the upstream model
    v_qualify_new_documents = dbt.ref('v_qualify_new_documents')
    
    # Filter for question analysis type
    document_all_pages = v_qualify_new_documents.filter(
        F.lower(F.col('doc_type')) == 'question'
    )
    
    document_all_pages = document_all_pages.with_column(
        'question_extracts_json',
        F.call_builtin(
            'AI_EXTRACT',
            F.call_builtin('TO_FILE', F.lit(f'{docs_stage}'), F.col('relative_path')),
            reponse_schema
        )
    )    
    return document_all_pages
