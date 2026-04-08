
-- ============================================================================
-- Incident Management Project - Database-Level Objects & Ownership Transfer (SYSADMIN)
--
-- PURPOSE: Creates all database-level objects (schemas, tables, stages, streams,
--          git repo, dbt project) and transfers ownership to dbt_project_admin_role.
--
-- PREREQUISITE: 01a_accountadmin_setup.sql must be executed first.
-- EXECUTION:    Must be executed by a user with the SYSADMIN role.
--
-- Context variables are populated from the yaml file under src/sql/snowflake.yml
-- ============================================================================


-- ============================================================================
-- PHASE 1: SYSADMIN - Create Database-Level Objects
-- ============================================================================

USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE <% ctx.env.dbt_project_database %>;

-- ----- Schemas -----

CREATE OR REPLACE SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone;

CREATE OR REPLACE SCHEMA <% ctx.env.dbt_project_database %>.silver_zone;
CREATE OR REPLACE SCHEMA <% ctx.env.dbt_project_database %>.gold_zone;
CREATE OR REPLACE SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- ----- Stages -----

CREATE OR REPLACE STAGE <% ctx.env.dbt_project_database %>.bronze_zone.csv_stage;

CREATE STAGE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.documents
  DIRECTORY = (ENABLE = true)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE <% ctx.env.dbt_project_database %>.gold_zone.agent_specs
  DIRECTORY = (ENABLE = true)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  COMMENT = 'Stage for storing agent specification files with server-side encryption';

-- ----- Streams -----

CREATE OR REPLACE STREAM <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream
  ON STAGE <% ctx.env.dbt_project_database %>.bronze_zone.documents;


PUT file://../cortex_agents/*.yml @<% ctx.env.dbt_project_database %>.gold_zone.agent_specs OVERWRITE=TRUE AUTO_COMPRESS=FALSE;


-- ============================================================================
-- PHASE 2: SYSADMIN - Transfer Ownership to dbt_project_admin_role
-- ============================================================================

GRANT OWNERSHIP ON DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT CREATE SCHEMA ON DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE <% ctx.env.dbt_project_database %> TO ROLE <% ctx.env.dbt_project_admin_role %>;
GRANT OWNERSHIP ON SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON SCHEMA <% ctx.env.dbt_project_database %>.silver_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON SCHEMA <% ctx.env.dbt_project_database %>.gold_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL TABLES IN SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL STAGES IN SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL STREAMS IN SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL TABLES IN SCHEMA <% ctx.env.dbt_project_database %>.gold_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL STAGES IN SCHEMA <% ctx.env.dbt_project_database %>.gold_zone
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL SECRETS IN SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL GIT REPOSITORIES IN SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL DBT PROJECTS IN SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments
  TO ROLE <% ctx.env.dbt_project_admin_role %> COPY CURRENT GRANTS;


