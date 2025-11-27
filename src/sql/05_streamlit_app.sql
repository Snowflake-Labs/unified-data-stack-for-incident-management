use role accountadmin;

CREATE WAREHOUSE IF NOT EXISTS <% ctx.env.streamlit_query_wh %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;

GRANT USAGE ON WAREHOUSE <% ctx.env.streamlit_query_wh %> TO ROLE <% ctx.env.dbt_project_admin_role %>;

use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.gold_zone;

-------------------------------------------------
-- Create Streamlit App for Incident Management Dashboard
-------------------------------------------------

CREATE OR REPLACE STREAMLIT <% ctx.env.dbt_project_database %>.gold_zone.incident_management_dashboard
  ROOT_LOCATION = '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo/branches/main/src/streamlit'
  MAIN_FILE = '/main.py'
  QUERY_WAREHOUSE = <% ctx.env.streamlit_query_wh %>
  COMMENT = 'Incident Management Dashboard - Monitor, track, and analyze incidents in real-time';

