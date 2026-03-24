-- ============================================================================
-- Incident Management Project - Teardown Script
-- 
-- PURPOSE: Safely removes Snowflake resources OWNED by dbt_project_admin_role
-- 
-- IMPORTANT: This script only drops objects created/owned by the project role.
-- Objects owned by ACCOUNTADMIN (database, warehouses, integrations, roles)
-- are listed in a separate section at the end for optional manual cleanup.
--
-- Execute using the dbt_project_admin_role for owned objects.
-- ============================================================================

-- ============================================================================
-- PHASE 1: PRE-TEARDOWN VALIDATION
-- Run these queries first to verify no active dependencies
-- ============================================================================

-- Uncomment to check for active sessions using project roles
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY()) 
-- WHERE ROLE_NAME IN ('<% ctx.env.dbt_project_admin_role %>', '<% ctx.env.slack_connector_role %>')
--   AND END_TIME IS NULL;

-- ============================================================================
-- PHASE 2: SUSPEND AND DROP TASKS (owned by dbt_project_admin_role)
-- Tasks must be suspended before dropping to avoid errors
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;
USE SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- Suspend all tasks (root tasks MUST be suspended before child tasks)

-- DAG 1: Daily Incremental Refresh
ALTER TASK IF EXISTS incm_root_daily_incremental_refresh SUSPEND;
ALTER TASK IF EXISTS incm_project_compile SUSPEND;
ALTER TASK IF EXISTS incm_daily_models_refresh SUSPEND;

-- DAG 2: Triggered Docs Processing
ALTER TASK IF EXISTS incm_root_triggered_docs_processing SUSPEND;
ALTER TASK IF EXISTS incm_triggered_docs_processing SUSPEND;

-- DAG 3: Deploy Cortex Services
ALTER TASK IF EXISTS incm_root_deploy_cortex_services SUSPEND;
ALTER TASK IF EXISTS incm_deploy_semantic_view SUSPEND;
ALTER TASK IF EXISTS incm_deploy_search_service SUSPEND;
ALTER TASK IF EXISTS incm_deploy_cortex_agent SUSPEND;

-- Drop tasks (child tasks before parent tasks)
-- DAG 3: Deploy Cortex Services
DROP TASK IF EXISTS incm_deploy_cortex_agent;
DROP TASK IF EXISTS incm_deploy_search_service;
DROP TASK IF EXISTS incm_deploy_semantic_view;
DROP TASK IF EXISTS incm_root_deploy_cortex_services;

-- DAG 2: Triggered Docs Processing
DROP TASK IF EXISTS incm_triggered_docs_processing;
DROP TASK IF EXISTS incm_root_triggered_docs_processing;

-- DAG 1: Daily Incremental Refresh
DROP TASK IF EXISTS incm_daily_models_refresh;
DROP TASK IF EXISTS incm_project_compile;
DROP TASK IF EXISTS incm_root_daily_incremental_refresh;

-- ============================================================================
-- PHASE 3: DROP CORTEX SERVICES (owned by dbt_project_admin_role)
-- Drop Cortex Agent, Cortex Search Service, and Semantic Views
-- ============================================================================

USE ROLE <% ctx.env.dbt_project_admin_role %>;
USE DATABASE <% ctx.env.dbt_project_database %>;

-- Drop Cortex Agent
DROP AGENT IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incm360_a1;

-- Drop Cortex Search Service
-- DROP CORTEX SEARCH SERVICE IF EXISTS <% ctx.env.dbt_project_database %>.silver_zone.incm_doc_search;

-- Drop Semantic View
DROP VIEW IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incm360;

-- ============================================================================
-- PHASE 4: DROP STREAMLIT APP (owned by dbt_project_admin_role)
-- ============================================================================

DROP STREAMLIT IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incident_management_dashboard;

-- ============================================================================
-- PHASE 5: DROP DBT PROJECT AND GIT REPOSITORY (owned by dbt_project_admin_role)
-- ============================================================================

USE SCHEMA <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- Drop DBT Project
DROP DBT PROJECT IF EXISTS <% ctx.env.dbt_project_database %>.dbt_project_deployments.<% ctx.env.dbt_project_name %>;

-- Drop Git Repository
DROP GIT REPOSITORY IF EXISTS <% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo;

-- Drop Git Secret
DROP SECRET IF EXISTS <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret;

-- ============================================================================
-- PHASE 6: DROP FUNCTIONS AND PROCEDURES (owned by dbt_project_admin_role)
-- ============================================================================

DROP FUNCTION IF EXISTS <% ctx.env.dbt_project_database %>.dbt_project_deployments.read_stage_file(STRING);

-- ============================================================================
-- PHASE 7: DROP TABLES (owned by dbt_project_admin_role)
-- Drop in order respecting foreign key constraints
-- ============================================================================

USE SCHEMA <% ctx.env.dbt_project_database %>.gold_zone;

-- Drop tables with foreign keys first
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments;
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history;
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.incidents;

-- Drop tables referenced by foreign keys
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.users;

-- Drop any dbt-generated models/views in gold_zone
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.active_incidents;
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.closed_incidents;
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.quaterly_review_metrics;

-- Drop any dbt-generated models/views in silver_zone
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.silver_zone.document_full_extracts;
DROP TABLE IF EXISTS <% ctx.env.dbt_project_database %>.silver_zone.document_question_extracts;

-- Drop any dbt-generated models/views in bronze_zone
DROP VIEW IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_new_documents;
DROP VIEW IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.v_qualify_slack_messages;

-- ============================================================================
-- PHASE 8: DROP STREAMS (owned by dbt_project_admin_role)
-- ============================================================================

DROP STREAM IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream;

-- ============================================================================
-- PHASE 9: DROP STAGES (owned by dbt_project_admin_role)
-- WARNING: This will delete all files in the stages
-- ============================================================================

DROP STAGE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.csv_stage;
DROP STAGE IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone.documents;
DROP STAGE IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone.agent_specs;

-- ============================================================================
-- PHASE 10: DROP SCHEMAS (owned by dbt_project_admin_role)
-- ============================================================================

DROP SCHEMA IF EXISTS <% ctx.env.dbt_project_database %>.dbt_project_deployments;
DROP SCHEMA IF EXISTS <% ctx.env.dbt_project_database %>.silver_zone;
DROP SCHEMA IF EXISTS <% ctx.env.dbt_project_database %>.gold_zone;
DROP SCHEMA IF EXISTS <% ctx.env.dbt_project_database %>.bronze_zone;

-- ============================================================================
-- POST-TEARDOWN VERIFICATION
-- Run these queries to confirm cleanup was successful
-- ============================================================================

-- Uncomment to verify objects are dropped
-- SHOW SCHEMAS IN DATABASE <% ctx.env.dbt_project_database %>;
-- SHOW TASKS IN DATABASE <% ctx.env.dbt_project_database %>;
-- SHOW CORTEX SEARCH SERVICES IN DATABASE <% ctx.env.dbt_project_database %>;

-- ============================================================================
-- ============================================================================
-- ACCOUNTADMIN-OWNED RESOURCES (OPTIONAL - MANUAL CLEANUP)
-- 
-- The following resources are owned by ACCOUNTADMIN, not dbt_project_admin_role.
-- Uncomment and run these ONLY if you want to completely remove all project
-- infrastructure including shared resources.
--
-- WARNING: These may be shared with other projects. Review carefully!
-- ============================================================================
-- ============================================================================

-- USE ROLE ACCOUNTADMIN;

-- ----------------------------------------------------------------------------
-- REVOKE ROLE GRANTS (run before dropping roles)
-- ----------------------------------------------------------------------------

-- REVOKE ROLE <% ctx.env.dbt_project_admin_role %> FROM USER <% ctx.env.snowflake_user %>;
-- REVOKE ROLE <% ctx.env.dbt_project_admin_role %> FROM ROLE SYSADMIN;

-- REVOKE ROLE <% ctx.env.slack_connector_role %> FROM USER <% ctx.env.snowflake_user %>;
-- REVOKE ROLE <% ctx.env.slack_connector_role %> FROM USER <% ctx.env.openflow_user %>;
-- REVOKE ROLE <% ctx.env.slack_connector_role %> FROM ROLE <% ctx.env.openflow_runtime_usage_role %>;
-- REVOKE ROLE <% ctx.env.slack_connector_role %> FROM ROLE SYSADMIN;

-- ----------------------------------------------------------------------------
-- REVOKE PRIVILEGES FROM ROLES
-- ----------------------------------------------------------------------------

-- REVOKE EXECUTE TASK ON ACCOUNT FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE EXECUTE MANAGED TASK ON ACCOUNT FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE USAGE ON WAREHOUSE <% ctx.env.dbt_pipeline_wh %> FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE USAGE ON WAREHOUSE <% ctx.env.cortex_search_wh %> FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE USAGE ON WAREHOUSE <% ctx.env.streamlit_query_wh %> FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE USAGE ON INTEGRATION <% ctx.env.snowflake_git_api_int %> FROM ROLE <% ctx.env.dbt_project_admin_role %>;
-- REVOKE USAGE ON WAREHOUSE <% ctx.env.slack_connector_wh %> FROM ROLE <% ctx.env.slack_connector_role %>;

-- ----------------------------------------------------------------------------
-- DROP DATABASE (owned by ACCOUNTADMIN)
-- WARNING: Only run if schemas were not dropped above, or to clean up empty DB
-- ----------------------------------------------------------------------------

-- DROP DATABASE IF EXISTS <% ctx.env.dbt_project_database %>;

-- ----------------------------------------------------------------------------
-- DROP WAREHOUSES (owned by ACCOUNTADMIN)
-- WARNING: These may be shared with other projects
-- ----------------------------------------------------------------------------

-- ALTER WAREHOUSE IF EXISTS <% ctx.env.dbt_pipeline_wh %> SUSPEND;
-- ALTER WAREHOUSE IF EXISTS <% ctx.env.cortex_search_wh %> SUSPEND;
-- ALTER WAREHOUSE IF EXISTS <% ctx.env.slack_connector_wh %> SUSPEND;
-- ALTER WAREHOUSE IF EXISTS <% ctx.env.streamlit_query_wh %> SUSPEND;

-- DROP WAREHOUSE IF EXISTS <% ctx.env.dbt_pipeline_wh %>;
-- DROP WAREHOUSE IF EXISTS <% ctx.env.cortex_search_wh %>;
-- DROP WAREHOUSE IF EXISTS <% ctx.env.slack_connector_wh %>;
-- DROP WAREHOUSE IF EXISTS <% ctx.env.streamlit_query_wh %>;

-- ----------------------------------------------------------------------------
-- DROP API INTEGRATION (owned by ACCOUNTADMIN)
-- ----------------------------------------------------------------------------

-- DROP INTEGRATION IF EXISTS <% ctx.env.snowflake_git_api_int %>;

-- ----------------------------------------------------------------------------
-- DROP ROLES (owned by ACCOUNTADMIN)
-- Must be dropped last after all grants are revoked
-- ----------------------------------------------------------------------------

-- DROP ROLE IF EXISTS <% ctx.env.slack_connector_role %>;
-- DROP ROLE IF EXISTS <% ctx.env.dbt_project_admin_role %>;

-- ============================================================================
-- END OF TEARDOWN SCRIPT
-- ============================================================================
