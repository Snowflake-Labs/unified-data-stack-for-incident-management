
-- ============================================================================
-- Incident Management Project - Load Gold Zone Test Data
--
-- PURPOSE: Uploads gold-zone seed CSV files to CSV_STAGE, creates tables that
--          back the dbt gold_zone models, and loads sample data.
--          Truncates existing data before loading.
--
-- PREREQUISITE: Schemas and stages must exist (created by 01b_sysadmin_objects.sql).
--
-- Context variables are populated from the yaml file under src/sql/snowflake.yml
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;
USE SCHEMA <% ctx.env.dbt_project_database %>.gold_zone;

-- ============================================================================
-- PHASE 1: UPLOAD CSV FILES TO STAGE
-- ============================================================================

PUT file://../../data/csv/seed_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_active_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/active_incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_closed_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/closed_incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_incident_comment_history.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_incident_attachments.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_attachments/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_document_full_extracts.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_full_extracts/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_quaterly_review_metrics.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/quaterly_review_metrics/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- ============================================================================
-- PHASE 2: CREATE TABLES
-- DDL derived from dbt model schemas in models/gold_zone/*.yml
-- Uses CREATE OR REPLACE to guarantee schema matches the expected layout,
-- since dbt may have previously created these tables with different types.
-- ============================================================================

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incidents (
    incident_number VARCHAR,
    category VARCHAR,
    title VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    reportee_id VARCHAR,
    created_at TIMESTAMP_NTZ,
    closed_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN,
    slack_message_id VARCHAR,
    last_comment VARCHAR
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.active_incidents (
    incident_number VARCHAR,
    title VARCHAR,
    category VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    assignee_name VARCHAR,
    reportee_id VARCHAR,
    reportee_name VARCHAR,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    age_hours NUMBER,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.closed_incidents (
    incident_number VARCHAR,
    title VARCHAR,
    category VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    reportee_id VARCHAR,
    created_at TIMESTAMP_NTZ,
    closed_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN,
    total_resolution_hours NUMBER(10,2),
    closed_month DATE,
    closed_year NUMBER,
    closed_quarter NUMBER
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history (
    id VARCHAR,
    incident_number VARCHAR,
    author_id VARCHAR,
    content VARCHAR,
    created_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments (
    id VARCHAR,
    incident_number VARCHAR,
    attachment_file VARCHAR,
    uploaded_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.document_full_extracts (
    relative_path VARCHAR,
    size NUMBER,
    last_modified TIMESTAMP_NTZ,
    md5 VARCHAR,
    etag VARCHAR,
    file_url VARCHAR,
    doc_type VARCHAR,
    extension VARCHAR,
    page_num NUMBER,
    chunk VARCHAR,
    headers VARCHAR
);

CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.quaterly_review_metrics (
    filename VARCHAR,
    metric VARCHAR,
    value VARCHAR,
    created_at TIMESTAMP_NTZ
);

-- ============================================================================
-- PHASE 3: LOAD DATA
-- All CSV timestamp columns use 'YYYY-MM-DD HH24:MI:SS' format.
-- ============================================================================

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.active_incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/active_incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.closed_incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/closed_incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_attachments/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.document_full_extracts
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_full_extracts/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.gold_zone.quaterly_review_metrics
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/quaterly_review_metrics/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- ============================================================================
-- PHASE 5: VALIDATION
-- ============================================================================

SELECT 'INCIDENTS' AS table_name, COUNT(*) AS row_count FROM <% ctx.env.dbt_project_database %>.gold_zone.incidents
UNION ALL SELECT 'ACTIVE_INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.active_incidents
UNION ALL SELECT 'CLOSED_INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.closed_incidents
UNION ALL SELECT 'INCIDENT_COMMENT_HISTORY', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history
UNION ALL SELECT 'INCIDENT_ATTACHMENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments
UNION ALL SELECT 'DOCUMENT_FULL_EXTRACTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.document_full_extracts
UNION ALL SELECT 'QUATERLY_REVIEW_METRICS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.gold_zone.quaterly_review_metrics;
