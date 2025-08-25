use role dbt_projects_admin;
use database incident_management;
use schema dbt_project_deployments;

-- Sync Snowflake Git repo from the cloud repo

-- Add new version of the dbt project 
ALTER DBT PROJECT IF EXISTS dbt_incident_management ADD VERSION 
  FROM '@incident_management.dbt_project_deployments.incident_management_dbt_project_repo/branches/main/incident_management/src/incident_management'

-- Set the new version as the default version
ALTER DBT PROJECT IF EXISTS dbt_incident_management SET
  DEFAULT_VERSION = LAST
  COMMENT = 'Incident Management Dbt Project';
