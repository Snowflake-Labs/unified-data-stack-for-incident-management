# Architecture Documentation

This document describes the technical architecture, data models, and project structure of the Incident Management platform.

## Table of Contents
- [System Architecture](#system-architecture)
- [Data Flow](#data-flow)
- [Data Models](#data-models)
- [Project Structure](#project-structure)

## System Architecture

The platform follows a modern data stack architecture built entirely on Snowflake:

```
┌─────────────────┐       ┌──────────────────┐         ┌─────────────────┐
│   Slack App     │──────▶│   OpenFlow       │────────▶│   Snowflake     │
│                 │       │  Slack Connector │         |    Bronze Zone  │
└─────────────────┘       └──────────────────┘         └─────────────────┘
                                                               │
                                                               ▼
┌─────────────────┐        ┌─────────────────┐           ┌──────────────────┐
│   Streamlit     │◀───────│   Snowflake     │◀──────────│   dbt Trans-     │
│   Dashboard     │        │   Gold Zone     │           | - formations     │
└─────────────────┘        └─────────────────┘           └──────────────────┘
```

### Components

#### 1. Slack App (Source)
- User-facing interface for incident reporting
- Supports text messages and image attachments
- Integrated via OpenFlow connector

#### 2. OpenFlow Slack Connector (Ingestion)
- Real-time data ingestion from Slack
- Automatic message and file capture
- Stores raw data in Bronze Zone tables

#### 3. Bronze Zone (Raw Data)
- Landing zone for raw Slack data
- Minimal transformations
- Source of truth for all incidents

#### 4. dbt Transformations (Processing)
- Business logic implementation
- AI-powered classification and enrichment
- Incremental processing for performance
- Data quality testing

#### 5. Gold Zone (Analytics-Ready)
- Business-ready data models
- Enriched incident records
- Pre-aggregated metrics and trends

#### 6. Streamlit Dashboard (Visualization)
- Real-time operational monitoring
- Interactive incident management
- Trend analysis and reporting

## Data Flow

### Incident Lifecycle

1. **Ingestion**: User posts incident message in Slack
   - OpenFlow captures message metadata
   - Attachments are stored and linked
   - Raw data lands in `SLACK_MESSAGES` table

2. **Qualification**: dbt processes raw messages
   - Filters relevant incident messages
   - Deduplicates records
   - Creates qualified view for processing

3. **Enrichment**: AI-powered classification
   - Text analysis using Cortex AI functions
   - Image classification for attachments
   - Category and priority assignment

4. **Structuring**: Incident record creation
   - Generates unique incident IDs
   - Links to reporters and assignees
   - Creates comment and attachment records

5. **Visualization**: Dashboard updates
   - Real-time metrics calculation
   - Active incident tracking
   - Trend analysis

## Data Models

### Bronze Zone

#### `users`
User directory for assignees and reporters.

**Schema:**
- `user_id`: Unique user identifier
- `username`: Slack username
- `email`: User email address
- `full_name`: Display name
- `is_active`: Account status

**Source:** [`models/bronze_zone/users.sql`](../src/incident_management/models/bronze_zone/users.sql)

#### `v_qualify_slack_messages`
Qualified and filtered Slack messages ready for incident processing.

**Purpose:**
- Filters incident-related messages
- Removes duplicates
- Prepares data for transformation

**Source:** [`models/bronze_zone/v_qualify_slack_messages.sql`](../src/incident_management/models/bronze_zone/v_qualify_slack_messages.sql)

### Gold Zone

#### `incidents`
Core incident records with AI-powered classification.

**Key Features:**
- Unique incident ID generation (INC-YYYY-XXXX)
- AI-based category classification
- Priority assignment (Critical, High, Medium, Low)
- Multi-modal AI analysis (text + images)

**Schema:**
- `incident_id`: Unique incident identifier
- `title`: Incident summary
- `description`: Detailed description
- `category`: AI-classified category
- `priority`: Business priority level
- `status`: Current status (Open, In Progress, Closed)
- `reporter_id`: User who reported the incident
- `assigned_to`: User assigned to resolve
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

**Source:** [`models/gold_zone/incidents.sql`](../src/incident_management/models/gold_zone/incidents.sql)

#### `incident_comment_history`
Chronological updates and comments for incidents.

**Purpose:**
- Track incident discussion threads
- Maintain audit trail
- Support collaboration

**Source:** [`models/gold_zone/incident_comment_history.sql`](../src/incident_management/models/gold_zone/incident_comment_history.sql)

#### `incident_attachments`
File attachments with metadata (as ingested from Slack).

**Features:**
- Links attachments to incidents
- Stores file metadata
- Enables attachment viewing in dashboard

**Source:** [`models/gold_zone/incident_attachments.sql`](../src/incident_management/models/gold_zone/incident_attachments.sql)

#### `active_incidents`
Currently open incidents with enriched data.

**Purpose:**
- Powers real-time dashboard
- Includes calculated fields (age, SLA status)
- Filtered view for operational monitoring

**Source:** [`models/gold_zone/active_incidents.sql`](../src/incident_management/models/gold_zone/active_incidents.sql)

#### `closed_incidents`
Resolved incidents with resolution metrics.

**Metrics:**
- Time to resolution
- Resolution quality
- Historical trends

**Source:** [`models/gold_zone/closed_incidents.sql`](../src/incident_management/models/gold_zone/closed_incidents.sql)

#### `weekly_incident_trends`
Weekly trend analysis for reporting.

**Aggregations:**
- Incidents by category
- Average resolution time
- Volume trends

**Source:** [`models/gold_zone/weekly_incident_trends.sql`](../src/incident_management/models/gold_zone/weekly_incident_trends.sql)

## Project Structure

```
incident-management/
├── data/                          # Sample data and test files
│   ├── csv/                       # CSV seed data
│   │   ├── incident_comment_history.csv
│   │   ├── incidents.csv
│   │   ├── slack_conversation_history.csv
│   │   └── users.csv
│   ├── exports/                   # Generated reports
│   │   └── incm_quaterly_review_metrics_2025_Q2.pdf
│   └── images/                    # Sample incident attachments
│       ├── invalid_credentials.jpeg
│       └── payment_gateway_outage.jpeg
│
├── docs/                          # Documentation
│   ├── ARCHITECTURE.md            # This file
│   ├── DEMOS.md                   # Usage examples
│   ├── SETUP.md                   # Installation guide
│   └── TROUBLESHOOTING.md         # Common issues
│
├── python_scripts/                # Python utilities and report generators
│   ├── generate_incident_report_pptx.py
│   └── incm_quaterly_review_metrics_*.md
│
├── screenshots/                   # Documentation screenshots
│   ├── destination_params.png
│   └── snowflake_role_params.png
│
├── src/
│   ├── incident_management/       # dbt project
│   │   ├── analyses/              # Ad-hoc analysis queries
│   │   ├── logs/                  # dbt execution logs
│   │   │   └── dbt.log
│   │   ├── macros/                # Custom dbt macros
│   │   │   ├── clean_stale_documents.sql
│   │   │   ├── create_cortex_agent.sql
│   │   │   └── generate_schema_name.sql
│   │   ├── models/                # Data models
│   │   │   ├── bronze_zone/       # Raw staging/views
│   │   │   │   ├── users.sql
│   │   │   │   ├── users.yml
│   │   │   │   ├── v_qualify_slack_messages.sql
│   │   │   │   └── v_qualify_slack_messages.yml
│   │   │   ├── gold_zone/         # Analytics-ready models
│   │   │   │   ├── active_incidents.sql
│   │   │   │   ├── active_incidents.yml
│   │   │   │   ├── closed_incidents.sql
│   │   │   │   ├── closed_incidents.yml
│   │   │   │   ├── incident_attachments.sql
│   │   │   │   ├── incident_attachments.yml
│   │   │   │   ├── incident_comment_history.sql
│   │   │   │   ├── incident_comment_history.yml
│   │   │   │   ├── incidents.sql
│   │   │   │   ├── incidents.yml
│   │   │   │   ├── weekly_incident_trends.sql
│   │   │   │   └── weekly_incident_trends.yml
│   │   │   └── sources.yml        # Source definitions and tests
│   │   ├── seeds/                 # Static reference data
│   │   ├── snapshots/             # Historical data snapshots
│   │   ├── target/                # dbt build artifacts (generated)
│   │   ├── tests/                 # Custom data tests
│   │   ├── dbt_project.yml        # dbt configuration
│   │   └── profiles.yml           # Database connections
│   │
│   ├── cortex_agents/             # Cortex Agent specifications
│   │   └── incm360_agent_1.yml    # Incident management agent
│   │
│   ├── logs/                      # Application logs
│   │   └── dbt.log
│   │
│   ├── scripts/                   # Deployment and setup scripts
│   │   ├── create_snowflake_yaml.sh
│   │   ├── dbtdeploy.sh
│   │   ├── dbtexec.sh
│   │   └── snowflake.yml.template
│   │
│   ├── sql/                       # Raw SQL scripts
│   │   ├── 01_dbt_projects_stack.sql      # Infrastructure setup
│   │   ├── 02_slack_connector.sql         # Slack integration
│   │   ├── 04_procs_and_funcs.sql         # Stored procedures
│   │   └── snowflake.yml                  # Snowflake config
│   │
│   └── streamlit/                 # Dashboard application
│       ├── main.py                # Main dashboard
│       └── snowflake.png          # Assets
│
├── .gitignore                     # Git ignore rules
├── Makefile                       # Automation tasks
├── requirements.txt               # Python dependencies
└── README.md                      # Project overview
```

### Key Directories

- **`data/`**: Sample and seed data for testing and initial setup
- **`docs/`**: All documentation in modular format
- **`src/incident_management/`**: Core dbt project with data models
- **`src/sql/`**: Infrastructure setup and raw SQL scripts
- **`src/streamlit/`**: Interactive dashboard application
- **`python_scripts/`**: Utility scripts for reporting and automation

## Design Principles

### 1. Separation of Concerns
- Bronze Zone: Raw data ingestion (no business logic)
- Gold Zone: Business logic and analytics (fully transformed)

### 2. Incremental Processing
- Models process only new/changed data
- Optimized for performance at scale

### 3. AI-Native Design
- AI functions embedded in SQL transformations
- Multi-modal analysis (text and images)
- No external AI infrastructure needed

### 4. Real-Time Architecture
- Near real-time ingestion from Slack
- Incremental updates to dashboard
- On-demand refresh capability

### 5. Testability
- Data quality tests in dbt
- Source freshness checks
- Schema validation

## Technology Stack

- **Data Warehouse**: Snowflake
- **Data Transformation**: dbt (on Snowflake runtime)
- **Data Ingestion**: OpenFlow SPCS
- **AI/ML**: Snowflake Cortex AI Functions
- **Visualization**: Streamlit in Snowflake
- **Orchestration**: Snowflake Tasks
- **Version Control**: Git

## Next Steps

- Review [Demo Vignettes](DEMOS.md) to see the system in action
- Check [Setup Guide](SETUP.md) for installation instructions
- Explore the actual model files in `src/incident_management/models/`

