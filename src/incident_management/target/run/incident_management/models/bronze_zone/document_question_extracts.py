
  
    
    
import snowflake.snowpark.functions as F
from snowflake.snowpark import Session

    
def model(dbt, session: Session):

    dbt.config(
        materialized='table',
        description='Table to store question extracts from documents'
    )
    
    docs_stage = dbt.config.get("docs_stage_path")

    all_meta = dbt.config.get("meta")
    
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
    ).drop(
        "METADATA$ACTION",
        "METADATA$ISUPDATE",
        "METADATA$ROW_ID"
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


config_dict = {'docs_stage_path': '@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS', 'meta': {'global_inm_policy_schema': {'enabled': False, 'schema': {'type': 'object', 'properties': {'purpose': {'description': 'Purpose of this policy', 'type': 'string'}, 'objectives': {'description': 'Objectives achieved by this policy', 'type': 'string'}, 'policy_statement': {'description': 'Primary policy statement', 'type': 'string'}, 'in_scope_services': {'description': 'Services explicitly in scope', 'type': 'array'}, 'out_of_scope_services': {'description': 'Services explicitly out of scope', 'type': 'array'}, 'geographical_coverage': {'description': 'Countries/regions covered', 'type': 'array'}, 'business_units_in_scope': {'description': 'Business units covered by the policy', 'type': 'array'}, 'applicability_conditions': {'description': 'Conditions determining when policy applies', 'type': 'array'}, 'exclusions': {'description': 'Explicit exceptions to scope', 'type': 'array'}, 'definitions_and_glossary': {'description': 'Terms, acronyms, and reference standards', 'type': 'object', 'properties': {'defined_terms': {'description': 'Key defined terms', 'type': 'array'}, 'acronyms': {'description': 'Acronyms used within the document', 'type': 'array'}, 'reference_standards': {'description': 'Referenced standards and frameworks', 'type': 'array'}}}}}}, 'quaterly_review_metrics': {'enabled': True, 'schema': {'type': 'object', 'properties': {'quarter': {'description': 'What is the year and quarter of the review metrics?', 'type': 'string'}, 'service_operational_health': {'description': 'Service operational health for a given quarter', 'type': 'object', 'properties': {'overall_uptime': {'description': 'What was the actual recorded overall uptime of all services', 'type': 'number'}, 'critical_services_uptime': {'description': 'What was the actual recorded  uptime of critical services', 'type': 'number'}, 'sev_1_incidents': {'description': 'What were the actual recorded number of Sev-1 incidents', 'type': 'number'}, 'sev_2_incidents': {'description': 'What were the actual recorded number of Sev-2 incidents', 'type': 'number'}, 'mtta': {'description': 'What was the actual recorded mean time to acknowledge an incident', 'type': 'number'}, 'mttr': {'description': 'What was the actual recorded mean time to recover from an incident', 'type': 'number'}, 'change_failure_rate': {'description': 'What was the actual recorded change failure rate', 'type': 'number'}, 'slo_breaches': {'description': 'What was the actual recorded number of SLO breaches', 'type': 'number'}, 'error_budget_consumed': {'description': 'What was the actual recorded error budget consumed', 'type': 'number'}, 'service_downtime': {'description': 'What was the actual recorded service downtime', 'type': 'number'}, 'unplanned_outage_hours': {'description': 'What was the actual recorded unplanned outage hours', 'type': 'number'}, 'planned_maintenance_hours': {'description': 'What was the actual recorded planned maintenance hours', 'type': 'number'}, 'sev_1_outage_minutes': {'description': 'What was the actual recorded Sev-1 outage minutes', 'type': 'number'}, 'sev_2_outage_minutes': {'description': 'What was the actual recorded Sev-2 outage minutes', 'type': 'number'}, 'longest_single_outage': {'description': 'What was the actual recorded longest single outage', 'type': 'number'}, 'mtbft': {'description': 'What was the actual recorded mean time between failures', 'type': 'number'}}}, 'team_utilisation': {'description': 'Team utilisation for a given quarter', 'type': 'object', 'properties': {'end_of_quarter_it_headcount': {'description': 'What was the actual recorded end of quarter IT headcount', 'type': 'number'}, 'engineering_headcount': {'description': 'What was the actual recorded engineering headcount', 'type': 'number'}, 'on_call_coverage': {'description': 'What was the actual recorded on call coverage', 'type': 'number'}, 'project_work_allocation': {'description': 'What was the actual recorded project work allocation', 'type': 'number'}, 'bau_operations_allocation': {'description': 'What was the actual recorded BAU/Operations allocation', 'type': 'number'}, 'on_call_hours_per_engineer': {'description': 'What was the actual recorded on call hours per engineer', 'type': 'number'}, 'after_hours_incidents_handled': {'description': 'What was the actual recorded after hours incidents handled', 'type': 'number'}, 'training_hours_per_fte': {'description': 'What was the actual recorded training hours per FTE', 'type': 'number'}, 'certifications_earned': {'description': 'What was the actual recorded certifications earned', 'type': 'number'}, 'attrition': {'description': 'What was the actual recorded attrition', 'type': 'number'}}}, 'tool_licensing_spend': {'description': 'Tool licensing spend for a given quarter', 'type': 'object', 'properties': {'atlassian_spend': {'description': 'What was the actual spend on Atlassian licenses', 'type': 'number'}, 'github_spend': {'description': 'What was the actual spend on GitHub licenses', 'type': 'number'}, 'slack_spend': {'description': 'What was the actual spend on Slack licenses', 'type': 'number'}, 'pagerduty_spend': {'description': 'What was the actual spend on PagerDuty licenses', 'type': 'number'}, 'datadog_spend': {'description': 'What was the actual spend on Datadog licenses', 'type': 'number'}, 'sentry_spend': {'description': 'What was the actual spend on Sentry licenses', 'type': 'number'}, 'okta_spend': {'description': 'What was the actual spend on Okta licenses', 'type': 'number'}, 'aws_spend': {'description': 'What was the actual spend on AWS licenses', 'type': 'number'}, 'total_spend': {'description': 'What was the actual spend on total licenses', 'type': 'number'}}}}}}}}


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

  