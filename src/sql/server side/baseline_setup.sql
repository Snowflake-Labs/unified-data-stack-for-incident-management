-- Incident Management System Setup Script for Snowflake
-- Designed for ecommerce incident tracking with analytics and reporting capabilities
-- Run this script to set up the complete incident management system


-- Create some useful database functions for reporting
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

-- =============================================
-- dbt_projects_admin role grants
-- =============================================
use role dbt_projects_admin;
create or replace database incident_management;
CREATE OR REPLACE WAREHOUSE incident_management_dbt_wh WAREHOUSE_SIZE='X-SMALL' INITIALLY_SUSPENDED=TRUE;
grant all privileges on all schemas in database incident_management to role dbt_projects_admin;
grant all privileges on future schemas in database incident_management to role dbt_projects_admin;
create or replace schema incident_management.DBT_PROJECT_DEPLOYMENTS;
grant usage on database incident_management to role dbt_projects_engineer;
grant usage on warehouse incident_management_dbt_wh to role dbt_projects_engineer;

grant usage on warehouse compute_wh to role dbt_projects_engineer;

grant create schema on database incident_management to role dbt_projects_engineer;

-- =============================================
-- CORE ENTITIES
-- =============================================

use role dbt_projects_engineer;
use database incident_management;
create or replace schema incident_management.landing_zone;
-- create or replace schema incident_management.transformed_zone;
create or replace schema incident_management.curated_zone;

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
    reporter_id STRING NOT NULL,
    assignee_id STRING,
    
    -- Business context
    affected_customers_count INTEGER DEFAULT 0,
    estimated_revenue_impact DECIMAL(12,2),
    customer_id STRING, -- Reference to customer if customer-specific
    order_id VARCHAR(100), -- Reference to order if order-specific
    
    -- Resolution tracking
    resolution_summary STRING,
    root_cause STRING,
    resolution_category VARCHAR(100),
    
    -- Timestamps
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    acknowledged_at TIMESTAMP_TZ,
    first_response_at TIMESTAMP_TZ,
    resolved_at TIMESTAMP_TZ,
    closed_at TIMESTAMP_TZ,
    updated_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- SLA tracking
    sla_breach BOOLEAN DEFAULT false,
    sla_due_at TIMESTAMP_TZ,
    
    -- System fields
    source_system VARCHAR(100), -- Where the incident originated (e.g., 'monitoring', 'customer_portal', 'manual')
    external_source_id VARCHAR(100), -- Reference to external source systems
    has_attachments BOOLEAN DEFAULT false, -- Indicates if incident has any attachments
    
    CONSTRAINT fk_incidents_reporter FOREIGN KEY (reporter_id) REFERENCES incident_management.landing_zone.users(id),
    CONSTRAINT fk_incidents_assignee FOREIGN KEY (assignee_id) REFERENCES incident_management.landing_zone.users(id)
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

SELECT 'Setup completed successfully!' AS setup_step;

