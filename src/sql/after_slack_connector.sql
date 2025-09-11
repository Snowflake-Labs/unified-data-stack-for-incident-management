use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.landing_zone;

CREATE OR REPLACE STREAM stream_slack_messages 
ON TABLE slack_messages 
APPEND_ONLY = TRUE;
