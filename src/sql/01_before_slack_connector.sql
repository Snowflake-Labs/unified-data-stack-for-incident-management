-- context variables are populated in the yaml file under scripts/snowflake.yml
-- Run me before setting up the Slack connector on your Openflow runtime.

use role <% ctx.env.dbt_project_admin_role %>;

create or replace database <% ctx.env.dbt_project_database %>;
CREATE OR REPLACE WAREHOUSE <% ctx.env.dbt_snowflake_warehouse %> WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;
create or replace schema <% ctx.env.dbt_project_database %>.landing_zone;
create or replace schema <% ctx.env.dbt_project_database %>.curated_zone;
create or replace schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;


-- Users table (employees, customers, system users)
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.landing_zone.users (
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
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.landing_zone.incidents (
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
    CONSTRAINT fk_incidents_assignee FOREIGN KEY (assignee_id) REFERENCES <% ctx.env.dbt_project_database %>.landing_zone.users(id),
    CONSTRAINT fk_incidents_reportee FOREIGN KEY (reportee_id) REFERENCES <% ctx.env.dbt_project_database %>.landing_zone.users(id)
);

-- Simplified comments table for incident communication
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.landing_zone.incident_comment_history (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    author_id STRING NOT NULL,
    content STRING NOT NULL,
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT fk_comment_history_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.landing_zone.incidents(incident_number),
    CONSTRAINT fk_comment_history_author FOREIGN KEY (author_id) REFERENCES <% ctx.env.dbt_project_database %>.landing_zone.users(id)
);

-- File attachments
CREATE OR REPLACE TABLE <% ctx.env.dbt_project_database %>.landing_zone.incident_attachments (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    attachment_file FILE,
    uploaded_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT fk_attachments_incident FOREIGN KEY (incident_number) REFERENCES <% ctx.env.dbt_project_database %>.landing_zone.incidents(incident_number)
);

use database <% ctx.env.dbt_project_database %>;
use schema dbt_project_deployments;

CREATE OR REPLACE SECRET <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret
  TYPE = password
  USERNAME = '<% ctx.env.git_user_email %>'
  PASSWORD = '<% ctx.env.git_user_repo_pat %>';

CREATE OR REPLACE GIT REPOSITORY <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_dbt_project_repo
ORIGIN = '<% ctx.env.git_repository_url %>'
API_INTEGRATION = <% ctx.env.snowflake_git_api_int %>
GIT_CREDENTIALS = <% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_git_secret


-- create a new dbt project using Git repo as source
CREATE DBT PROJECT IF NOT EXISTS dbt_incident_management
    FROM '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.incident_management_dbt_project_repo/branches/main/<% ctx.env.repo_dbt_projects_yml_path %>'
    DEFAULT_VERSION = LAST;


-- provides grants to the dbt_projects_engineer role on the dbt project
grant usage on dbt project dbt_incident_management to role <% ctx.env.dbt_project_admin_role %>;



