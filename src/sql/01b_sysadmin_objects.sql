
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

-- ----- Tables -----

-- CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.bronze_zone.users (
--     id STRING PRIMARY KEY DEFAULT UUID_STRING(),
--     email VARCHAR(255) UNIQUE NOT NULL,
--     first_name VARCHAR(100) NOT NULL,
--     last_name VARCHAR(100) NOT NULL,
--     role VARCHAR(50) NOT NULL,
--     department VARCHAR(100),
--     team VARCHAR(100),
--     is_active BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
--     updated_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP()
-- );

-- CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incidents (
--     incident_number VARCHAR(50) PRIMARY KEY,
--     title VARCHAR(255) NOT NULL,
--     category STRING,
--     priority VARCHAR(20) NOT NULL,
--     status VARCHAR(30) NOT NULL DEFAULT 'open',
--     assignee_id STRING,
--     reportee_id STRING,
--     created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
--     closed_at TIMESTAMP_TZ,
--     updated_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
--     source_system VARCHAR(100),
--     external_source_id VARCHAR(100),
--     has_attachments BOOLEAN DEFAULT FALSE,
--     slack_message_id VARCHAR(100),
--     last_comment STRING,
--     CONSTRAINT fk_incidents_assignee FOREIGN KEY (assignee_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id),
--     CONSTRAINT fk_incidents_reportee FOREIGN KEY (reportee_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id)
-- );

-- CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history (
--     id STRING PRIMARY KEY DEFAULT UUID_STRING(),
--     incident_number VARCHAR(50) NOT NULL,
--     author_id STRING NOT NULL,
--     content STRING NOT NULL,
--     created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
--     CONSTRAINT fk_comment_history_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.gold_zone.incidents(incident_number),
--     CONSTRAINT fk_comment_history_author FOREIGN KEY (author_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id)
-- );

-- CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments (
--     id STRING PRIMARY KEY DEFAULT UUID_STRING(),
--     incident_number VARCHAR(50) NOT NULL,
--     attachment_file FILE,
--     uploaded_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
--     CONSTRAINT fk_attachments_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.gold_zone.incidents(incident_number)
-- );

-- ----- Git Repository & dbt Project -----

CREATE OR REPLACE SECRET <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret
  TYPE = PASSWORD
  USERNAME = '<% ctx.env.git_user_email %>'
  PASSWORD = '<% ctx.env.git_user_repo_pat %>';

CREATE OR REPLACE GIT REPOSITORY <% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo
  ORIGIN = '<% ctx.env.git_repository_url %>'
  API_INTEGRATION = <% ctx.env.snowflake_git_api_int %>
  GIT_CREDENTIALS = <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret;

CREATE DBT PROJECT <% ctx.env.dbt_project_database %>.dbt_project_deployments.<% ctx.env.dbt_project_name %>
  FROM '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo/branches/<% ctx.env.git_branch %>/src/incident_management'
  EXTERNAL_ACCESS_INTEGRATIONS = (<% ctx.env.dbt_deps_eai %>)
  COMMENT = 'generates incident management data models';

-- ----- Agent Specifications -----

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


-- ============================================================================
-- PHASE 3: Verification (as dbt_project_admin_role)
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;

SHOW SCHEMAS IN DATABASE <% ctx.env.dbt_project_database %>;
SHOW TABLES IN SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone;
SHOW TABLES IN SCHEMA <% ctx.env.dbt_project_database %>.gold_zone;
SHOW STAGES IN SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone;
SHOW STAGES IN SCHEMA <% ctx.env.dbt_project_database %>.gold_zone;
SHOW GIT REPOSITORIES IN SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments;
SHOW DBT PROJECTS IN SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- ============================================================================
-- END OF SYSADMIN SETUP & OWNERSHIP TRANSFER
-- ============================================================================
