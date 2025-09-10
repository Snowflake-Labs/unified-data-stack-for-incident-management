use role accountadmin;

create or replace role dbt_projects_admin;
create or replace role dbt_projects_engineer;
grant database role snowflake.cortex_user to role dbt_projects_engineer; 

grant usage on integration git_int_clakkad to role dbt_projects_admin;

grant usage on integration allow_all_eai to role dbt_projects_admin;

grant create database on account to role dbt_projects_admin;
grant create warehouse on account to role dbt_projects_admin;
grant role dbt_projects_engineer to role dbt_projects_admin;
grant role dbt_projects_engineer to user openflow_svc_usr;
grant role dbt_projects_admin to user clakkad;
