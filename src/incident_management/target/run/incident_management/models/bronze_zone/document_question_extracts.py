
  
    
    
import snowflake.snowpark.functions as F
from snowflake.snowpark import Session
import json

    
def model(dbt, session: Session):
    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
    docs_stage = dbt.config.get("docs_stage_path")
    global_inm_policy_schema = dbt.config.get("meta")['global_inm_policy_schema']

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
            F.call_builtin('TO_FILE', F.lit('@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS'), F.col('relative_path')),
            global_inm_policy_schema
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


config_dict = {'docs_stage_path': None, 'meta': {'global_inm_policy_schema': {'schema': {'type': 'object', 'properties': {'purpose': {'description': 'Purpose of this policy', 'type': 'string'}, 'objectives': {'description': 'Objectives achieved by this policy', 'type': 'string'}, 'policy_statement': {'description': 'Primary policy statement', 'type': 'string'}, 'in_scope_services': {'description': 'Services explicitly in scope', 'type': 'array'}, 'out_of_scope_services': {'description': 'Services explicitly out of scope', 'type': 'array'}, 'geographical_coverage': {'description': 'Countries/regions covered', 'type': 'array'}, 'business_units_in_scope': {'description': 'Business units covered by the policy', 'type': 'array'}, 'applicability_conditions': {'description': 'Conditions determining when policy applies', 'type': 'array'}, 'exclusions': {'description': 'Explicit exceptions to scope', 'type': 'array'}, 'definitions_and_glossary': {'description': 'Terms, acronyms, and reference standards', 'type': 'object', 'properties': {'defined_terms': {'description': 'Key defined terms', 'type': 'array'}, 'acronyms': {'description': 'Acronyms used within the document', 'type': 'array'}, 'reference_standards': {'description': 'Referenced standards and frameworks', 'type': 'array'}}}}}}}}


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



def materialize(session, df, target_relation):
    # make sure pandas exists
    import importlib.util
    package_name = 'pandas'
    if importlib.util.find_spec(package_name):
        import pandas
        if isinstance(df, pandas.core.frame.DataFrame):
          session.use_database(target_relation.database)
          session.use_schema(target_relation.schema)
          # session.write_pandas does not have overwrite function
          df = session.createDataFrame(df)
    
    df.write.mode("overwrite").save_as_table('incident_management.bronze_zone.document_question_extracts', table_type='transient')

def main(session):
    dbt = dbtObj(session.table)
    df = model(dbt, session)
    materialize(session, df, dbt.this)
    return "OK"

  