-- ============================================================================
-- Incident Management Project - Load Test Data
--
-- PURPOSE: Uploads CSV test data to the CSV_STAGE and loads into bronze and
--          gold tables. Truncates existing data before loading.
--
-- PREREQUISITE: 01b_sysadmin_objects.sql must be executed first to create
--               all schemas, tables, and stages.
--
-- Context variables are populated from the yaml file under src/sql/snowflake.yml
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;
USE SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone;

-- ============================================================================
-- PHASE 1: UPLOAD CSV FILES TO STAGE
-- ============================================================================

PUT file://../../data/csv/users.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/users/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/slack_messages.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_messages/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/slack_members.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_members/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/file_hashes.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/file_hashes/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/doc_metadata.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/doc_metadata/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/incident_comment_history.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- ============================================================================
-- PHASE 2: TRUNCATE EXISTING DATA
-- Gold tables first (foreign key dependencies), then bronze
-- ============================================================================

TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incidents;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_members;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.users;

-- ============================================================================
-- PHASE 3: LOAD BRONZE TABLES
-- ============================================================================

-- Users (load first - referenced by foreign keys)
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.users (id, email, first_name, last_name, role, department, team, is_active, created_at, updated_at)
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/users/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- Slack Messages
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_messages/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- Slack Members (ARRAY columns require SELECT transformation)
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.slack_members (conversationid, conversationtype, memberids, memberemails, isprivate, lastupdated)
  FROM (
    SELECT $1, $2, PARSE_JSON($3), PARSE_JSON($4), $5, $6
    FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_members/
  )
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- File Hashes
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/file_hashes/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- Doc Metadata
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/doc_metadata/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- ============================================================================
-- PHASE 4: LOAD GOLD TABLES
-- ============================================================================

-- Incidents (load before comment history - foreign key dependency)
COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- Incident Comment History
COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history (id, incident_number, author_id, content, created_at)
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- ============================================================================
-- PHASE 5: VALIDATION
-- ============================================================================

SELECT 'USERS' AS table_name, COUNT(*) AS row_count FROM <% ctx.env.dbt_project_database %>.bronze_zone.users
UNION ALL SELECT 'SLACK_MESSAGES', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages
UNION ALL SELECT 'SLACK_MEMBERS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.slack_members
UNION ALL SELECT 'FILE_HASHES', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes
UNION ALL SELECT 'DOC_METADATA', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.incidents
UNION ALL SELECT 'INCIDENT_COMMENT_HISTORY', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history;
