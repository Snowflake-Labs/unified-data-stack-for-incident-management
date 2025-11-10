-- context variables are populated in the yaml file under scripts/snowflake.yml
use role accountadmin;

create or replace warehouse <% ctx.env.slack_connector_wh %>
  with 
  warehouse_size = 'xsmall'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
  warehouse_type = 'standard'
  enable_query_acceleration = false
  comment = 'warehouse for ingestion through openflow spcs runtimes';

-- for simplicity, we are creating a single role for all openflow spcs runtimes and administration of deployments.
create or replace role <% ctx.env.slack_connector_role %>;

grant usage on database <% ctx.env.dbt_project_database %> to role <% ctx.env.slack_connector_role %>;

grant all privileges on future schemas in database <% ctx.env.dbt_project_database %> to role <% ctx.env.slack_connector_role %>;

grant usage on warehouse <% ctx.env.slack_connector_wh %> to role <% ctx.env.slack_connector_role %>;

grant role <% ctx.env.slack_connector_role %> to role sysadmin;

grant role <% ctx.env.slack_connector_role %> to role <% ctx.env.openflow_runtime_usage_role %>;
grant role <% ctx.env.slack_connector_role %> to user <% ctx.env.snowflake_user %>;

grant role <% ctx.env.slack_connector_role %> to user <% ctx.env.openflow_user %>;
