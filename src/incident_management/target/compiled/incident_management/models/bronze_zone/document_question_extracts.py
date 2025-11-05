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
            F.call_builtin('TO_FILE', F.lit(f'{docs_stage}/qa'), F.col('relative_path')),
            get_response_format(asset_path, F.col('relative_path'))
        )
    )
    
    return document_all_pages


# This part is user provided model code
# you will need to copy the next section to run the code
# COMMAND ----------
# this part is dbt logic for get ref work, do not modify

def ref(*args, **kwargs):
    refs = {"v_qualify_new_documents": "incident_management.bronze_zone.v_qualify_new_documents"}
    key = '.'.join(args)
    version = kwargs.get("v") or kwargs.get("version")
    if version:
        key += f".v{version}"
    dbt_load_df_function = kwargs.get("dbt_load_df_function")
    return dbt_load_df_function(refs[key])


def source(*args, dbt_load_df_function):
    sources = {}
    key = '.'.join(args)
    return dbt_load_df_function(sources[key])


config_dict = {'asset-paths': None, 'docs_stage_path': None}


class config:
    def __init__(self, *args, **kwargs):
        pass

    @staticmethod
    def get(key, default=None):
        return config_dict.get(key, default)

class this:
    """dbt.this() or dbt.this.identifier"""
    database = "incident_management"
    schema = "bronze_zone"
    identifier = "document_question_extracts"
    
    def __repr__(self):
        return 'incident_management.bronze_zone.document_question_extracts'


class dbtObj:
    def __init__(self, load_df_function) -> None:
        self.source = lambda *args: source(*args, dbt_load_df_function=load_df_function)
        self.ref = lambda *args, **kwargs: ref(*args, **kwargs, dbt_load_df_function=load_df_function)
        self.config = config
        self.this = this()
        self.is_incremental = False

# COMMAND ----------


