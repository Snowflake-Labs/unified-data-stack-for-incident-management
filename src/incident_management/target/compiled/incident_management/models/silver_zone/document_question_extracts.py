import snowflake.snowpark.functions as F
from snowflake.snowpark import Session

    
def model(dbt, session: Session):

    dbt.config(
        materialized='incremental',
        incremental_strategy='append',
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


config_dict = {'docs_stage_path': '@INCIDENT_MANAGEMENT.bronze_zone.DOCUMENTS', 'meta': {'quaterly_review_metrics': {'enabled': True, 'schema': {'type': 'object', 'properties': {'quarter': {'description': 'What is the year and quarter of the review metrics?', 'type': 'string'}, 'overall_uptime': {'description': 'What was the actual recorded overall uptime of all services', 'type': 'string'}, 'critical_services_uptime': {'description': 'What was the actual recorded  uptime of critical services', 'type': 'string'}, 'sev_1_incidents': {'description': 'What were the actual recorded string of Sev-1 incidents', 'type': 'string'}, 'sev_2_incidents': {'description': 'What were the actual recorded string of Sev-2 incidents', 'type': 'string'}, 'mtta': {'description': 'What was the actual recorded mean time to acknowledge an incident', 'type': 'string'}, 'mttr': {'description': 'What was the actual recorded mean time to recover from an incident', 'type': 'string'}, 'change_failure_rate': {'description': 'What was the actual recorded change failure rate', 'type': 'string'}, 'slo_breaches': {'description': 'What was the actual recorded string of SLO breaches', 'type': 'string'}, 'error_budget_consumed': {'description': 'What was the actual recorded error budget consumed', 'type': 'string'}, 'service_downtime': {'description': 'What was the actual recorded service downtime', 'type': 'string'}, 'unplanned_outage_hours': {'description': 'What was the actual recorded unplanned outage hours', 'type': 'string'}, 'planned_maintenance_hours': {'description': 'What was the actual recorded planned maintenance hours', 'type': 'string'}, 'sev_1_outage_minutes': {'description': 'What was the actual recorded Sev-1 outage minutes', 'type': 'string'}, 'sev_2_outage_minutes': {'description': 'What was the actual recorded Sev-2 outage minutes', 'type': 'string'}, 'longest_single_outage': {'description': 'What was the actual recorded longest single outage', 'type': 'string'}, 'mtbft': {'description': 'What was the actual recorded mean time between failures', 'type': 'string'}, 'end_of_quarter_it_headcount': {'description': 'What was the actual recorded end of quarter IT headcount', 'type': 'string'}, 'engineering_headcount': {'description': 'What was the actual recorded engineering headcount', 'type': 'string'}, 'on_call_coverage': {'description': 'What was the actual recorded on call coverage', 'type': 'string'}, 'project_work_allocation': {'description': 'What was the actual recorded project work allocation', 'type': 'string'}, 'bau_operations_allocation': {'description': 'What was the actual recorded BAU/Operations allocation', 'type': 'string'}, 'on_call_hours_per_engineer': {'description': 'What was the actual recorded on call hours per engineer', 'type': 'string'}, 'after_hours_incidents_handled': {'description': 'What was the actual recorded after hours incidents handled', 'type': 'string'}, 'training_hours_per_fte': {'description': 'What was the actual recorded training hours per FTE', 'type': 'string'}, 'certifications_earned': {'description': 'What was the actual recorded certifications earned', 'type': 'string'}, 'attrition': {'description': 'What was the actual recorded attrition', 'type': 'string'}, 'atlassian_spend': {'description': 'What was the actual spend on Atlassian licenses', 'type': 'string'}, 'github_spend': {'description': 'What was the actual spend on GitHub licenses', 'type': 'string'}, 'slack_spend': {'description': 'What was the actual spend on Slack licenses', 'type': 'string'}, 'pagerduty_spend': {'description': 'What was the actual spend on PagerDuty licenses', 'type': 'string'}, 'datadog_spend': {'description': 'What was the actual spend on Datadog licenses', 'type': 'string'}, 'sentry_spend': {'description': 'What was the actual spend on Sentry licenses', 'type': 'string'}, 'okta_spend': {'description': 'What was the actual spend on Okta licenses', 'type': 'string'}, 'aws_spend': {'description': 'What was the actual spend on AWS licenses', 'type': 'string'}, 'total_spend': {'description': 'What was the actual spend on total licenses', 'type': 'string'}}}}}}


class config:
    def __init__(self, *args, **kwargs):
        pass

    @staticmethod
    def get(key, default=None):
        return config_dict.get(key, default)

class this:
    """dbt.this() or dbt.this.identifier"""
    database = "incident_management"
    schema = "silver_zone"
    identifier = "document_question_extracts"
    
    def __repr__(self):
        return 'incident_management.silver_zone.document_question_extracts'


class dbtObj:
    def __init__(self, load_df_function) -> None:
        self.source = lambda *args: source(*args, dbt_load_df_function=load_df_function)
        self.ref = lambda *args, **kwargs: ref(*args, **kwargs, dbt_load_df_function=load_df_function)
        self.config = config
        self.this = this()
        self.is_incremental = True

# COMMAND ----------


