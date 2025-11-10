
-------------------------------------------------
-- service user and role for dbt projects
-- context variables are populated in the yaml file under scripts/snowflake.yml
-------------------------------------------------

use role accountadmin;

CREATE OR REPLACE API INTEGRATION <% ctx.env.snowflake_git_api_int %>
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('<% ctx.env.git_repository_url %>')
  ALLOWED_AUTHENTICATION_SECRETS = ALL
  ENABLED = TRUE;

CREATE OR REPLACE DATABASE <% ctx.env.dbt_project_database %>;

CREATE OR REPLACE WAREHOUSE <% ctx.env.dbt_snowflake_warehouse %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;

/**

Optional: 

- If you plan to deploy dbt Projects from within Snowsight, you can use any human user 
with login access to Snowsight by granting the dbt_project_admin_role to the user

- Else, this is the user that will be used to deploy the dbt project via snow dbt commands

**/ 
-- create or replace user <% ctx.env.snowflake_user %>
-- type=service
-- default_warehouse=<% ctx.env.dbt_snowflake_warehouse %>
-- default_namespace=<% ctx.env.dbt_project_database %>
-- default_role=<% ctx.env.dbt_project_admin_role %>
-- comment='service user for dbt projects';

-- Create database roles for managing landing, curated zones, and dbt deployments
create or replace database role <% ctx.env.dbt_project_database %>.manage_bronze_zone;
create or replace database role <% ctx.env.dbt_project_database %>.manage_gold_zone;
create or replace database role <% ctx.env.dbt_project_database %>.manage_dbt_deployments;

grant usage on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_bronze_zone;
grant create schema on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_bronze_zone;

grant usage on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_gold_zone;
grant create schema on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_gold_zone;


grant usage on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_dbt_deployments;
grant create schema on database <% ctx.env.dbt_project_database %> to database role <% ctx.env.dbt_project_database %>.manage_dbt_deployments;


create or replace role <% ctx.env.dbt_project_admin_role %>;

grant database role snowflake.cortex_user to role <% ctx.env.dbt_project_admin_role %>; 
grant database role manage_bronze_zone to role <% ctx.env.dbt_project_admin_role %>;
grant database role manage_gold_zone to role <% ctx.env.dbt_project_admin_role %>;
grant database role manage_dbt_deployments to role <% ctx.env.dbt_project_admin_role %>;

grant usage on integration <% ctx.env.snowflake_git_api_int %> to role <% ctx.env.dbt_project_admin_role %>;
grant usage on warehouse <% ctx.env.dbt_snowflake_warehouse %> to role <% ctx.env.dbt_project_admin_role %>;
grant execute task on account to role <% ctx.env.dbt_project_admin_role %>;
grant role <% ctx.env.dbt_project_admin_role %> to role sysadmin;
grant role <% ctx.env.dbt_project_admin_role %> to user <% ctx.env.snowflake_user %>;


use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;

create or replace schema <% ctx.env.dbt_project_database %>.bronze_zone;
grant all privileges on schema <% ctx.env.dbt_project_database %>.bronze_zone to database role <% ctx.env.dbt_project_database %>.manage_bronze_zone;

create or replace stage <% ctx.env.dbt_project_database %>.bronze_zone.csv_stage;

create stage if not exists <% ctx.env.dbt_project_database %>.bronze_zone.documents
DIRECTORY=(ENABLE=true)
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

create or replace stream <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream
on stage <% ctx.env.dbt_project_database %>.bronze_zone.documents;

create or replace schema <% ctx.env.dbt_project_database %>.gold_zone;
grant all privileges on schema <% ctx.env.dbt_project_database %>.gold_zone to database role <% ctx.env.dbt_project_database %>.manage_gold_zone;

-- Users table (employees, customers, system users)
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.bronze_zone.users (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    department VARCHAR(100),
    team VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP()
);

-- Main incidents table
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incidents (
    incident_number VARCHAR(50) PRIMARY KEY, -- Human-readable incident ID (e.g., INC-2024-001)
    title VARCHAR(255) NOT NULL,
    
    -- Classification
    category STRING,
    priority VARCHAR(20) NOT NULL,
    
    -- Status tracking
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    
    -- People involved
    assignee_id STRING,
    reportee_id STRING,
        
    -- Timestamps
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    closed_at TIMESTAMP_TZ,
    updated_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
        
    -- System fields
    source_system VARCHAR(100), -- Where the incident originated (e.g., 'monitoring', 'customer_portal', 'manual')
    external_source_id VARCHAR(100), -- Reference to external source systems
    has_attachments BOOLEAN DEFAULT false, -- Indicates if incident has any attachments
    slack_message_id VARCHAR(100), -- Reference to the original Slack message that created this incident
    last_comment STRING, -- Most recent comment content for this incident
    CONSTRAINT fk_incidents_assignee FOREIGN KEY (assignee_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id),
    CONSTRAINT fk_incidents_reportee FOREIGN KEY (reportee_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id)
);

-- Simplified comments table for incident communication
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    author_id STRING NOT NULL,
    content STRING NOT NULL,
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT fk_comment_history_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.gold_zone.incidents(incident_number),
    CONSTRAINT fk_comment_history_author FOREIGN KEY (author_id) REFERENCES <% ctx.env.dbt_project_database %>.bronze_zone.users(id)
);

-- File attachments
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.gold_zone.incident_attachments (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    attachment_file FILE,
    uploaded_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT fk_attachments_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.gold_zone.incidents(incident_number)
);

put file://../../data/csv/users.csv  @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage overwrite=true;
put file://../../data/csv/incidents.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage overwrite=true;
put file://../../data/csv/incident_comment_history.csv @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage overwrite=true;

copy into <% ctx.env.dbt_project_database %>.bronze_zone.users from 
    @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/users.csv 
    file_format = (type = csv field_delimiter = ',' skip_header = 1);
copy into <% ctx.env.dbt_project_database %>.gold_zone.incidents from 
    @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incidents.csv 
    file_format = (type = csv field_delimiter = ',' skip_header = 1);
copy into <% ctx.env.dbt_project_database %>.gold_zone.incident_comment_history from 
    @<% ctx.env.dbt_project_database %>.bronze_zone.csv_stage/incident_comment_history.csv 
    file_format = (type = csv field_delimiter = ',' skip_header = 1);


create or replace schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;
grant all privileges on schema <% ctx.env.dbt_project_database %>.dbt_project_deployments to database role <% ctx.env.dbt_project_database %>.manage_dbt_deployments;


CREATE OR REPLACE SECRET <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret
  TYPE = password
  USERNAME = '<% ctx.env.git_user_email %>'
  PASSWORD = '<% ctx.env.git_user_repo_pat %>';

CREATE OR REPLACE GIT REPOSITORY <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_dbt_project_repo
ORIGIN = '<% ctx.env.git_repository_url %>'
API_INTEGRATION = <% ctx.env.snowflake_git_api_int %>
GIT_CREDENTIALS = <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret;


CREATE DBT PROJECT <% ctx.env.dbt_project_database %>.dbt_project_deployments.<% ctx.env.dbt_project_name %>
  FROM '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_dbt_project_repo/branches/main/src/incident_management'
  COMMENT = 'generates incident management data models';

alter task if exists dbt_project_deployments.im_root_task_scheduler suspend;
alter task if exists dbt_project_deployments.im_project_run_select_bronze_zone suspend;
alter task if exists dbt_project_deployments.im_project_run_select_gold_zone suspend;
alter task if exists dbt_project_deployments.im_project_test suspend;
alter task if exists dbt_project_deployments.im_project_compile suspend;


create or replace task dbt_project_deployments.im_root_task_scheduler
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	schedule='USING CRON 1 0 * * * America/Toronto'
	config='{"target": "dev"}'
	as SELECT 1;

create or replace task dbt_project_deployments.im_project_compile
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.im_root_task_scheduler
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'compile --target '|| _target;

    EXECUTE DBT PROJECT dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$
  ;

create or replace task dbt_project_deployments.im_project_run_select_bronze_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.im_project_compile
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select bronze_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$;

create or replace task dbt_project_deployments.im_project_run_select_gold_zone
	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
	after dbt_project_deployments.im_project_compile, dbt_project_deployments.im_project_run_select_bronze_zone
	as 
  EXECUTE IMMEDIATE
  $$
    BEGIN
    LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
    LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
    LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
    LET command := 'run --select gold_zone --target '|| _target;
    EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
    END;
  $$;


-- create or replace task dbt_project_deployments.im_project_test
-- 	warehouse=<% ctx.env.dbt_snowflake_warehouse %>
-- 	after dbt_project_deployments.im_project_compile, dbt_project_deployments.im_project_run_select_bronze_zone, dbt_project_deployments.im_project_run_select_gold_zone
-- 	as
--   EXECUTE IMMEDIATE 
--   $$
--     BEGIN
--     LET _target := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('target'));
--     LET _dbt_nodes := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('select'));
--     LET _eai := (SELECT SYSTEM$GET_TASK_GRAPH_CONFIG('eai'));
--     LET command := 'test --target '|| _target;

--     EXECUTE dbt project dbt_project_deployments.<% ctx.env.dbt_project_name %> args=:command;
--     END;
--   $$;


