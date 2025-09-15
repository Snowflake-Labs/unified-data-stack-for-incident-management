use role dbt_projects_engineer;
use warehouse incident_management_dbt_wh;
use database incident_management;


-- -- Landing zone
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='compile';
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.users';
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.v_qualify_slack_messages';
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.incidents';
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.incident_comment_history';
-- EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.incident_attachments';

-- execute dbt project incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run-operation clean_stale_documents --args {stage_name: @INCIDENT_MANAGEMENT.LANDING_ZONE.DOCUMENTS}';

EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone.incidents+';

EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select curated_zone';

