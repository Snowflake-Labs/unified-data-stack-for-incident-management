-- ============================================================================
-- Incident Management Project - Load Test Data
--
-- PURPOSE: Uploads all seed CSV files to CSV_STAGE, creates tables if they
--          don't exist, and loads data. Truncates existing data before loading.
--          Table names are derived from CSV filenames by stripping the 'seed_' prefix.
--
-- PREREQUISITE: Schemas and stages must exist (created by 01b_sysadmin_objects.sql).
--
-- Context variables are populated from the yaml file under src/sql/snowflake.yml
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;
USE SCHEMA <% ctx.env.dbt_project_database %>.bronze_zone;

-- ============================================================================
-- PHASE 1: UPLOAD CSV FILES TO STAGE
-- ============================================================================

PUT file://../../data/csv/seed_users.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/users/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_slack_messages.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_messages/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_slack_members.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_members/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_file_hashes.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/file_hashes/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_doc_metadata.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/doc_metadata/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_documents_stream.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/documents_stream/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_v_qualify_slack_messages.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/v_qualify_slack_messages/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_document_question_extracts.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_question_extracts/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_document_full_extracts.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_full_extracts/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_active_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/active_incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_closed_incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/closed_incidents/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_incident_comment_history.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_incident_attachments.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_attachments/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://../../data/csv/seed_quaterly_review_metrics.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/quaterly_review_metrics/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- ============================================================================
-- PHASE 2: CREATE TABLES (if not exist)
-- Column types sourced from data/csv/schema.yml
-- ============================================================================

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.users (
    id VARCHAR,
    email VARCHAR,
    first_name VARCHAR,
    last_name VARCHAR,
    role VARCHAR,
    department VARCHAR,
    team VARCHAR,
    is_active BOOLEAN,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages (
    hasfile BOOLEAN,
    hasfiles BOOLEAN,
    type VARCHAR,
    subtype VARCHAR,
    team VARCHAR,
    channel VARCHAR,
    user VARCHAR,
    username VARCHAR,
    text VARCHAR,
    ts VARCHAR,
    threadts VARCHAR,
    intro BOOLEAN,
    starred BOOLEAN,
    wibblr BOOLEAN,
    appid VARCHAR,
    botid VARCHAR,
    botlink VARCHAR,
    displayasbot BOOLEAN,
    upload BOOLEAN,
    parentuserid VARCHAR,
    clientmsgid VARCHAR,
    unfurllinks BOOLEAN,
    unfurlmedia BOOLEAN,
    threadbroadcast BOOLEAN,
    locked BOOLEAN,
    subscribed BOOLEAN,
    hidden BOOLEAN,
    nonotifications BOOLEAN,
    chunkindex NUMBER,
    chunkcount NUMBER,
    ingestts TIMESTAMP_NTZ,
    workspaceid VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_members (
    conversationid VARCHAR,
    conversationtype VARCHAR,
    memberids VARCHAR,
    memberemails VARCHAR,
    isprivate BOOLEAN,
    lastupdated TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes (
    hash_value VARCHAR,
    source_system VARCHAR,
    doc_id VARCHAR,
    event_ts TIMESTAMP_NTZ,
    algorithm VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata (
    event_ts VARCHAR,
    channel_id VARCHAR,
    user_id VARCHAR,
    file_id VARCHAR,
    file_name VARCHAR,
    file_mimetype VARCHAR,
    file_size NUMBER,
    content_sha256 VARCHAR,
    staged_file_path VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream (
    relative_path VARCHAR,
    size NUMBER,
    last_modified TIMESTAMP_NTZ,
    md5 VARCHAR,
    etag VARCHAR,
    file_url VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_slack_messages (
    hasfiles BOOLEAN,
    type VARCHAR,
    subtype VARCHAR,
    team VARCHAR,
    channel VARCHAR,
    user VARCHAR,
    username VARCHAR,
    reporter_id VARCHAR,
    text VARCHAR,
    ts VARCHAR,
    slack_message_id VARCHAR,
    file_id VARCHAR,
    file_name VARCHAR,
    file_mimetype VARCHAR,
    file_size NUMBER,
    staged_file_path VARCHAR,
    attachment_file VARCHAR,
    incident_number VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.document_question_extracts (
    relative_path VARCHAR,
    size NUMBER,
    last_modified TIMESTAMP_NTZ,
    md5 VARCHAR,
    etag VARCHAR,
    file_url VARCHAR,
    doc_type VARCHAR,
    extension VARCHAR,
    question_extracts_json VARIANT
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.document_full_extracts (
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

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incidents (
    incident_number VARCHAR,
    category VARCHAR,
    title VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    reportee_id VARCHAR,
    created_at VARCHAR,
    closed_at TIMESTAMP_NTZ,
    updated_at VARCHAR,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN,
    slack_message_id VARCHAR,
    last_comment VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.active_incidents (
    incident_number VARCHAR,
    title VARCHAR,
    category VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    assignee_name VARCHAR,
    reportee_id VARCHAR,
    reportee_name VARCHAR,
    created_at VARCHAR,
    updated_at VARCHAR,
    age_hours NUMBER,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.closed_incidents (
    incident_number VARCHAR,
    title VARCHAR,
    category VARCHAR,
    priority VARCHAR,
    status VARCHAR,
    assignee_id VARCHAR,
    reportee_id VARCHAR,
    created_at VARCHAR,
    closed_at TIMESTAMP_NTZ,
    updated_at VARCHAR,
    source_system VARCHAR,
    external_source_id VARCHAR,
    has_attachments BOOLEAN,
    total_resolution_hours NUMBER,
    closed_month DATE,
    closed_year NUMBER,
    closed_quarter NUMBER
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incident_comment_history (
    id VARCHAR,
    incident_number VARCHAR,
    author_id VARCHAR,
    content VARCHAR,
    created_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incident_attachments (
    id VARCHAR,
    incident_number VARCHAR,
    attachment_file VARCHAR,
    uploaded_at VARCHAR
);

CREATE TABLE IF NOT EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.quaterly_review_metrics (
    filename VARCHAR,
    metric VARCHAR,
    value VARCHAR,
    created_at TIMESTAMP_NTZ
);

-- ============================================================================
-- PHASE 3: TRUNCATE EXISTING DATA
-- ============================================================================

TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.quaterly_review_metrics;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incident_attachments;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incident_comment_history;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.closed_incidents;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.active_incidents;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.incidents;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.document_full_extracts;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.document_question_extracts;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_slack_messages;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_members;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages;
TRUNCATE TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.users;

-- ============================================================================
-- PHASE 4: LOAD DATA
-- ============================================================================

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.users
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/users/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_messages/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.slack_members
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/slack_members/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/file_hashes/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/doc_metadata/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/documents_stream/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_slack_messages
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/v_qualify_slack_messages/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- VARIANT column requires SELECT transformation
COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.document_question_extracts
    (relative_path, size, last_modified, md5, etag, file_url, doc_type, extension, question_extracts_json)
  FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8, TRY_PARSE_JSON($9)
    FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_question_extracts/
  )
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.document_full_extracts
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/document_full_extracts/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.active_incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/active_incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.closed_incidents
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/closed_incidents/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.incident_comment_history
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.incident_attachments
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_attachments/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

COPY INTO <% ctx.env.dbt_project_database %>.bronze_zone.quaterly_review_metrics
  FROM @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/quaterly_review_metrics/
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' EMPTY_FIELD_AS_NULL = TRUE);

-- ============================================================================
-- PHASE 5: VALIDATION
-- ============================================================================

SELECT 'USERS' AS table_name, COUNT(*) AS row_count FROM <% ctx.env.dbt_project_database %>.bronze_zone.users
UNION ALL SELECT 'SLACK_MESSAGES', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.slack_messages
UNION ALL SELECT 'SLACK_MEMBERS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.slack_members
UNION ALL SELECT 'FILE_HASHES', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.file_hashes
UNION ALL SELECT 'DOC_METADATA', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.doc_metadata
UNION ALL SELECT 'DOCUMENTS_STREAM', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream
UNION ALL SELECT 'V_QUALIFY_SLACK_MESSAGES', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_slack_messages
UNION ALL SELECT 'DOCUMENT_QUESTION_EXTRACTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.document_question_extracts
UNION ALL SELECT 'DOCUMENT_FULL_EXTRACTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.document_full_extracts
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.incidents
UNION ALL SELECT 'ACTIVE_INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.active_incidents
UNION ALL SELECT 'CLOSED_INCIDENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.closed_incidents
UNION ALL SELECT 'INCIDENT_COMMENT_HISTORY', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.incident_comment_history
UNION ALL SELECT 'INCIDENT_ATTACHMENTS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.incident_attachments
UNION ALL SELECT 'QUATERLY_REVIEW_METRICS', COUNT(*) FROM <% ctx.env.dbt_project_database %>.bronze_zone.quaterly_review_metrics;
