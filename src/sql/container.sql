use role <% ctx.env.dbt_project_admin_role %>;
create or replace database <% ctx.env.dbt_project_database %>;
CREATE OR REPLACE WAREHOUSE <% ctx.env.dbt_snowflake_warehouse %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;
create or replace schema <% ctx.env.dbt_project_database %>.landing_zone;
create or replace schema <% ctx.env.dbt_project_database %>.curated_zone;
create or replace schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;
