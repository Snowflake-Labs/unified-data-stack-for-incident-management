
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

CREATE WAREHOUSE IF NOT EXISTS <% ctx.env.dbt_pipeline_wh %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;
CREATE WAREHOUSE IF NOT EXISTS <% ctx.env.cortex_search_wh %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;

grant execute task on account to role <% ctx.env.dbt_project_admin_role %>;
grant execute managed task on account to role <% ctx.env.dbt_project_admin_role %>;

/**

Optional: 

- If you plan to deploy dbt Projects from within Snowsight, you can use any human user 
with login access to Snowsight by granting the dbt_project_admin_role to the user

- Else, this is the user that will be used to deploy the dbt project via snow dbt commands

**/ 
-- create or replace user <% ctx.env.snowflake_user %>
-- type=service
-- default_warehouse=<% ctx.env.dbt_pipeline_wh %>
-- default_namespace=<% ctx.env.dbt_project_database %>
-- default_role=<% ctx.env.dbt_project_admin_role %>
-- comment='service user for dbt projects';

-- Create  roles for managing landing, curated zones, and dbt deployments
create or replace role <% ctx.env.dbt_project_admin_role %>;
grant usage on database <% ctx.env.dbt_project_database %> to role <% ctx.env.dbt_project_admin_role %>;
grant create schema on database <% ctx.env.dbt_project_database %> to role <% ctx.env.dbt_project_admin_role %>; 
grant all privileges on future schemas in database <% ctx.env.dbt_project_database %> to role <% ctx.env.dbt_project_admin_role %>;
grant database role snowflake.cortex_user to role <% ctx.env.dbt_project_admin_role %>; 

grant usage on integration <% ctx.env.snowflake_git_api_int %> to role <% ctx.env.dbt_project_admin_role %>;
grant usage on warehouse <% ctx.env.dbt_pipeline_wh %> to role <% ctx.env.dbt_project_admin_role %>;
grant usage on warehouse <% ctx.env.cortex_search_wh %> to role <% ctx.env.dbt_project_admin_role %>;
grant execute task on account to role <% ctx.env.dbt_project_admin_role %>;
grant role <% ctx.env.dbt_project_admin_role %> to role sysadmin;
grant role <% ctx.env.dbt_project_admin_role %> to user <% ctx.env.snowflake_user %>;

use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;

create or replace schema <% ctx.env.dbt_project_database %>.bronze_zone;

create or replace stage <% ctx.env.dbt_project_database %>.bronze_zone.csv_stage;

create stage if not exists <% ctx.env.dbt_project_database %>.bronze_zone.documents
DIRECTORY=(ENABLE=true)
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

create or replace stream <% ctx.env.dbt_project_database %>.bronze_zone.documents_stream
on stage <% ctx.env.dbt_project_database %>.bronze_zone.documents;

create or replace schema <% ctx.env.dbt_project_database %>.gold_zone;

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


CREATE OR REPLACE SECRET <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret
  TYPE = password
  USERNAME = '<% ctx.env.git_user_email %>'
  PASSWORD = '<% ctx.env.git_user_repo_pat %>';

CREATE OR REPLACE GIT REPOSITORY <% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo
ORIGIN = '<% ctx.env.git_repository_url %>'
API_INTEGRATION = <% ctx.env.snowflake_git_api_int %>
GIT_CREDENTIALS = <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret;


CREATE DBT PROJECT <% ctx.env.dbt_project_database %>.dbt_project_deployments.<% ctx.env.dbt_project_name %>
  FROM '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo/branches/main/src/incident_management'
  COMMENT = 'generates incident management data models';


-------------------------------------------------
-- Create Stage for Agent Specifications
-------------------------------------------------

CREATE OR REPLACE STAGE <% ctx.env.dbt_project_database %>.gold_zone.agent_specs
  DIRECTORY = ( ENABLE = true )
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  COMMENT = 'Stage for storing agent specification files with server-side encryption';

PUT file://../cortex_agents/incm360_agent_1.yml  @<% ctx.env.dbt_project_database %>.gold_zone.agent_specs overwrite=true auto_compress=false;
