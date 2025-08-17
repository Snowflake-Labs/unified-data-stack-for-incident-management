use role dbt_projects_admin;
use database incident_management;
use schema DBT_PROJECT_DEPLOYMENTS;


-- connect to a Git repo where the dbt project is stored (without using a Workspace)
CREATE OR REPLACE GIT REPOSITORY incident_management_dbt_project_repo
ORIGIN = 'https://github.com/your-username/incident-management.git'
API_INTEGRATION = git_int_clakkad
GIT_CREDENTIALS = DEMO_DB.GIT_REPO_BASE.GENERAL_PURPOSE_GITHUB_PAT;


-- create a new dbt project using Git repo as source
CREATE OR REPLACE DBT PROJECT dbt_incident_management
    FROM '@incident_management.dbt_projects_git_repo/branches/main/incident_management'
    DEFAULT_VERSION = LAST;


-- provides grants to the dbt_projects_engineer role on the dbt project
grant usage on dbt project dbt_incident_management to role dbt_projects_engineer;






