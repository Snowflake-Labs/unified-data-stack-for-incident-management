
-- ============================================================================
-- Incident Management Project - Account-Level Infrastructure (ACCOUNTADMIN)
--
-- PURPOSE: Creates account-level objects required for the incident management
--          dbt project: API integration, database, warehouses, role, and grants.
--
-- PREREQUISITE: Must be executed by a user with the ACCOUNTADMIN role.
-- NEXT STEP:    Run 01b_sysadmin_objects.sql as SYSADMIN.
--
-- Context variables are populated from the yaml file under src/sql/snowflake.yml
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ----- API Integration -----

CREATE OR REPLACE API INTEGRATION <% ctx.env.snowflake_git_api_int %>
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('<% ctx.env.git_repository_url %>')
  ALLOWED_AUTHENTICATION_SECRETS = ALL
  ENABLED = TRUE;

-- ----- Database & Warehouses -----

CREATE OR REPLACE DATABASE <% ctx.env.dbt_project_database %>;

CREATE WAREHOUSE IF NOT EXISTS <% ctx.env.dbt_pipeline_wh %>
  WAREHOUSE_SIZE = 'X-SMALL'
  INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS <% ctx.env.cortex_search_wh %>
  WAREHOUSE_SIZE = 'X-SMALL'
  INITIALLY_SUSPENDED = TRUE;

-- ----- Role & Grants -----

CREATE OR REPLACE ROLE <% ctx.env.dbt_project_admin_role %>;

GRANT EXECUTE TASK ON ACCOUNT TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT DATABASE ROLE snowflake.cortex_user TO ROLE <% ctx.env.dbt_project_admin_role %>;

GRANT USAGE ON INTEGRATION <% ctx.env.snowflake_git_api_int %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT USAGE ON WAREHOUSE <% ctx.env.dbt_pipeline_wh %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT USAGE ON WAREHOUSE <% ctx.env.cortex_search_wh %> TO ROLE <% ctx.env.dbt_project_admin_role %>;

GRANT USAGE ON DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT CREATE SCHEMA ON DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;

GRANT USAGE ON INTEGRATION <% ctx.env.snowflake_git_api_int %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT USAGE ON INTEGRATION <% ctx.env.dbt_deps_eai %> TO ROLE <% ctx.env.dbt_project_admin_role %>;

GRANT ROLE <% ctx.env.dbt_project_admin_role %> TO ROLE SYSADMIN;
GRANT ROLE <% ctx.env.dbt_project_admin_role %> TO USER <% ctx.env.snowflake_user %>;

/**

Optional:

- If you plan to deploy dbt Projects from within Snowsight, you can use any human user
  with login access to Snowsight by granting the dbt_project_admin_role to the user

- Else, this is the user that will be used to deploy the dbt project via snow dbt commands

**/
-- CREATE OR REPLACE USER <% ctx.env.snowflake_user %>
--   TYPE = SERVICE
--   DEFAULT_WAREHOUSE = <% ctx.env.dbt_pipeline_wh %>
--   DEFAULT_NAMESPACE = <% ctx.env.dbt_project_database %>
--   DEFAULT_ROLE = <% ctx.env.dbt_project_admin_role %>
--   COMMENT = 'service user for dbt projects';

-- ============================================================================
-- END OF ACCOUNTADMIN SETUP
-- ============================================================================
