-- context variables are populated in the yaml file under scripts/snowflake.yml
use role accountadmin;

create or replace user genp_service_usr
TYPE=SERVICE
DEFAULT_WAREHOUSE=incident_management_dbt_wh
DEFAULT_NAMESPACE=incident_management
DEFAULT_ROLE=dbt_projects_engineer
COMMENT='Service user for dbt projects';


create or replace role dbt_projects_engineer;
grant database role snowflake.cortex_user to role dbt_projects_engineer; 
grant create warehouse on account to role dbt_projects_engineer;

grant role dbt_projects_engineer to user genp_service_usr;

ALTER USER IF EXISTS genp_service_usr
ADD PROGRAMMATIC ACCESS TOKEN genp_service_usr_pat1
ROLE_RESTRICTION = 'dbt_projects_engineer'
DAYS_TO_EXPIRY = 15;