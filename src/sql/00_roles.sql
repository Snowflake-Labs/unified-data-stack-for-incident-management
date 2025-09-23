-- context variables are populated in the yaml file under scripts/snowflake.yml
use role accountadmin;

create or replace role <% ctx.env.dbt_project_admin_role %>;
grant database role snowflake.cortex_user to role <% ctx.env.dbt_project_admin_role %>; 

grant usage on integration git_int_clakkad to role <% ctx.env.dbt_project_admin_role %>;

grant usage on integration allow_all_eai to role <% ctx.env.dbt_project_admin_role %>;

grant create database on account to role <% ctx.env.dbt_project_admin_role %>;
grant create warehouse on account to role <% ctx.env.dbt_project_admin_role %>;

grant role <% ctx.env.dbt_project_admin_role %> to user <% ctx.env.dbt_snowflake_user %>;
-- TODO: add command to add PAT to user
