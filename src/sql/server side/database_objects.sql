
use role dbt_projects_engineer;
create or replace database incident_management;
CREATE OR REPLACE WAREHOUSE incident_management_dbt_wh WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;

use database incident_management;
create or replace schema incident_management.landing_zone;
create or replace schema incident_management.curated_zone;
create or replace schema incident_management.dbt_project_deployments;

-- Users table (employees, customers, system users)
CREATE OR REPLACE TABLE incident_management.landing_zone.users (
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
CREATE OR REPLACE TABLE incident_management.landing_zone.incidents (
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
    
    CONSTRAINT fk_incidents_assignee FOREIGN KEY (assignee_id) REFERENCES incident_management.landing_zone.users(id),
    CONSTRAINT fk_incidents_reportee FOREIGN KEY (reportee_id) REFERENCES incident_management.landing_zone.users(id)
);

-- Simplified comments table for incident communication
CREATE OR REPLACE TABLE incident_management.landing_zone.incident_comment_history (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    author_id STRING NOT NULL,
    content STRING NOT NULL,
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT fk_comment_history_incident FOREIGN KEY (incident_number) REFERENCES incident_management.landing_zone.incidents(incident_number),
    CONSTRAINT fk_comment_history_author FOREIGN KEY (author_id) REFERENCES incident_management.landing_zone.users(id)
);

-- File attachments
CREATE OR REPLACE TABLE incident_management.landing_zone.incident_attachments (
    id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    incident_number VARCHAR(50) NOT NULL,
    attachment_file FILE,
    uploaded_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT fk_attachments_incident FOREIGN KEY (incident_number) REFERENCES incident_management.landing_zone.incidents(incident_number)
);


CREATE OR REPLACE STREAM incident_management.landing_zone.stream_slack_messages ON TABLE incident_management.landing_zone.slack_messages APPEND_ONLY = TRUE;


CREATE OR REPLACE SECRET incident_management.dbt_project_deployments.incident_management_git_secret
  TYPE = password
  USERNAME = '${GITHUB_USERNAME}'
  PASSWORD = '${GITHUB_PAT}';

CREATE OR REPLACE GIT REPOSITORY incident_management.dbt_project_deployments.incident_management_dbt_project_repo
ORIGIN = '${GITHUB_REPO_URL}'
API_INTEGRATION = ${SNOWFLAKE_GIT_API_INT}
GIT_CREDENTIALS = incident_management.dbt_project_deployments.incident_management_git_secret


SELECT 'Setup completed successfully!' AS setup_step;

