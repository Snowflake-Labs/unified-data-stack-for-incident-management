use role dbt_projects_engineer;
use warehouse incident_management_dbt_wh;
use database incident_management;



EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='compile';

EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select landing_zone';

EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select curated_zone';


EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select curated_zone.weekly_incident_trends';

EXECUTE DBT PROJECT incident_management.DBT_PROJECT_DEPLOYMENTS.dbt_incident_management args='run --select curated_zone.monthly_incident_trends';
