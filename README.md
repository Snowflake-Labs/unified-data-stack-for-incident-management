
## Table of Contents
- [An Unified Data Stack on Snowflake](#an-unified-data-stack-on-snowflake)
  - [Architecture](#architecture)
  - [Key Features](#key-features)
  - [Demo Vignettes](#demo-vignettes)
    - [1. OpenFlow-Based Slack Ingestion](#1-openflow-based-slack-ingestion)
    - [2. dbt Projects on Snowflake](#2-dbt-projects-on-snowflake)
    - [3. AI/SQL Integration within dbt Models](#3-aisql-integration-within-dbt-models)
    - [4. Streamlit Integration](#4-streamlit-integration)
    - [5. End-to-End Workflow Example](#5-end-to-end-workflow-example)
  - [Data Models](#data-models)
    - [Landing Zone](#landing-zone)
    - [Curated Zone](#curated-zone)
  - [Project Structure](#project-structure)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Environment Variables](#environment-variables)
    - [Installation](#installation)
    - [Setup Slack Connector (OpenFlow)](#setup-slack-connector-openflow)
  - [General Usage](#general-usage)
    - [Running the Dashboard](#running-the-dashboard)
    - [Dashboard Features](#dashboard-features)
    - [Managing Incidents via Slack](#managing-incidents-via-slack)
  - [Additional Resources](#additional-resources)
  - [Questions, Feedback, and Contribution](#questions-feedback-and-contribution)


# An Unified Data Stack on Snowflake

*This project demonstrates a modern data stack for an example real-life situaton that of incident management that typically requires multiple steps, and close collaboration between representatives using tools like Slack. This project uses a modern stack with Snowflake to bring AI-powered automation and real-time analytics to this known business process that can benefit from AI inclusion.*


An end-to-end incident management platform* built on Snowflake that demonstrates modern data engineering practices using dbt, AI/ML capabilities, and real-time visualization through Streamlit. The system ingests incident data from Slack via Snowflake's OpenFlow connector and provides intelligent categorization, tracking, and reporting capabilities.

*a small cross-section of a much larger process to show the art of possible 


## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Slack App     │───▶│   OpenFlow   │───▶│   Snowflake     │
│                 │    │  Connector   │    │   Landing Zone  │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                     │
                                                     ▼
┌─────────────────┐    ┌─────────────────┐    ┌──────────────────┐
│   Streamlit     │◀───│   Snowflake     │◀───│   dbt Trans-     │
│   Dashboard     │    │ Curated Zone    │    | - formations     │
└─────────────────┘    └─────────────────┘    └──────────────────┘
```


## Key Features

- **AI-Powered Classification**: Automatically categorizes incidents using Snowflake's AI functions
- **Image Processing**: AI analysis of attached images for incident categorization
- **Real-time Data Pipeline**: Ingests Slack messages and converts them to structured incident records
- **Interactive Dashboard**: Streamlit-based dashboard for monitoring and managing incidents
- **dbt Data Transformations**: Data modeling using one of the most popular build tool - dbt - on Snowflake provided runtime engine


## Demo Vignettes

This project demonstrates several key modern data platform capabilities through realistic incident management scenarios.

### 1. OpenFlow-Based Slack Ingestion

**Scenario**: Real-time incident reporting through Slack
- Users report incidents in dedicated Slack channels
- OpenFlow connector automatically ingests messages to Snowflake
- System processes both text and image attachments
- Demonstrates: Real-time data ingestion, unstructured data handling

**Demo Flow**:
1. Post incident message in Slack: "Payment gateway is returning 500 errors"
2. Attach screenshot of error page (use the sample image JPEG provided)
3. If Tasks are not setup, then run the dbt Project end-to-end
4. Watch as system creates structured incident record with AI classification

### 2. dbt Projects on Snowflake

**Scenario**: Working with dbt Projects in Snowflake
- Remote deployment and execution of dbt Projects using Snowflake CLI
- Using variables in [`dbt_project.yml`](src/incident_management/dbt_project.yml)
- Support for dbt command options as "select"
- Passing arguments using Task config to dbt commands executed using `EXECUTE DBT PROJECT`

**Scenario**: Scalable data transformation pipeline
- Raw Slack data transformed into analytics-ready models
- Incremental processing for performance
- Data quality testing and documentation
- Demonstrates: Modern data engineering practices, data lineage

**Key Models**:
- [`landing_zone.incidents`](src/incident_management/models/landing_zone/incidents.sql): AI-enhanced incident processing with image analysis
- [`curated_zone.active_incidents`](src/incident_management/models/curated_zone/active_incidents.sql): Business-ready incident tracking
- [`curated_zone.monthly_incident_trends`](src/incident_management/models/curated_zone/monthly_incident_trends.sql): Aggregated analytics

### 3. AI/SQL Integration within dbt Models

**Scenario**: Intelligent incident classification and processing

#### Unstructured Text Processing
```sql
-- Automatic incident categorization from Slack messages
ai_classify(sri.text, ['payment gateway error', 'login error', 'other']):labels[0] as category

-- Smart incident matching using natural language
ai_filter(
  prompt('The text category {0} is logically relatable to this record\'s category {1}', 
         text_category, roi.category)
)
```

#### Image Processing
```sql
-- AI analysis of attached screenshots
case 
    when sri.attachment_file is not null then 
        ai_classify(sri.attachment_file, ['payment gateway error', 'login error', 'other']):labels[0]
    else ai_classify(sri.text, ['payment gateway error', 'login error', 'other']):labels[0]
end as category
```

**Demonstrates**: AI-native data processing, multimodal analysis, intelligent data enrichment

> See the complete implementation in [`incidents.sql`](src/incident_management/models/landing_zone/incidents.sql)

### 4. Streamlit Integration

**Scenario**: Real-time operational dashboard
- Live incident monitoring and management
- Interactive attachment viewing
- Trend analysis and reporting
- Demonstrates: Data visualization, real-time analytics, user experience

**Dashboard Features**:
- Real-time incident metrics with priority-based color coding
- Sample trend charts powered by Snowflake analytics
- In-app image viewing for incident attachments

### 5. End-to-End Workflow Example

**Complete Incident Lifecycle**:
1. **Report**: "Our login page is showing 'Invalid credentials' for valid users" + screenshot
2. **Ingest**: OpenFlow captures message and image from Slack
3. **Process**: dbt transforms raw data:
   - AI classifies as "login error" (critical priority)
   - Image analysis confirms authentication issue
   - Creates incident record INC-2025-XXX
4. **Monitor**: Streamlit dashboard shows new critical incident
5. **Resolve**: Team addresses issue, updates status
6. **Analyze**: System tracks resolution time, updates trends

This demonstrates a complete modern data stack handling real-world operational scenarios with AI enhancement and real-time visibility.

## Data Models

### Landing Zone
- [`incidents`](src/incident_management/models/landing_zone/incidents.sql): Core incident records with AI-powered classification
- [`incident_comment_history`](src/incident_management/models/landing_zone/incident_comment_history.sql): Chronological updates and comments
- [`incident_attachments`](src/incident_management/models/landing_zone/incident_attachments.sql): File attachments with metadata (as ingested from Slack)
- [`users`](src/incident_management/models/landing_zone/users.sql): User directory for assignees and reporters

### Curated Zone
- [`active_incidents`](src/incident_management/models/curated_zone/active_incidents.sql): Currently open incidents with enriched data
- [`closed_incidents`](src/incident_management/models/curated_zone/closed_incidents.sql): Resolved incidents with resolution metrics
- [`monthly_incident_trends`](src/incident_management/models/curated_zone/monthly_incident_trends.sql): Aggregated monthly statistics
- [`weekly_incident_trends`](src/incident_management/models/curated_zone/weekly_incident_trends.sql): Weekly trend analysis


## Project Structure

```
incident-management/
├── data/                          # Sample data and test files
│   ├── csv/                      # CSV seed data
│   │   ├── incidents.csv         # Sample incident records
│   │   ├── incident_comment_history.csv
│   │   └── users.csv             # User directory
│   └── images/                   # Sample incident attachments
│       ├── invalid_credentials.jpeg
│       └── payment_gateway_outage.jpeg
├── src/
│   ├── incident_management/      # dbt project
│   │   ├── models/
│   │   │   ├── landing_zone/     # Raw data models
│   │   │   │   ├── incidents.sql        # Core incident processing
│   │   │   │   ├── incident_attachments.sql
│   │   │   │   ├── users.sql
│   │   │   │   └── v_*.sql              # Slack message views
│   │   │   ├── curated_zone/            # Analytics-ready models
│   │   │   │   ├── active_incidents.sql
│   │   │   │   ├── closed_incidents.sql
│   │   │   │   ├── monthly_incident_trends.sql
│   │   │   │   └── weekly_incident_trends.sql
│   │   │   └── schema.yml        # Model documentation
│   │   ├── macros/               # Custom dbt macros
│   │   ├── dbt_project.yml       # dbt configuration
│   │   └── profiles.yml          # Database connections
│   ├── scripts/                  # Deployment and setup scripts
│   │   ├── sqlsetup.sh          # Snowflake infrastructure setup
│   │   ├── dbtdeploy.sh         # dbt deployment automation
│   │   ├── dbtexec.sh           # dbt execution wrapper
│   │   └── snowflake.yml.template
│   ├── sql/                      # Raw SQL scripts
│   │   ├── 00_roles.sql         # Role and permission setup
│   │   ├── 01_before_slack_connector.sql
│   │   └── 02_orchestration.sql
│   └── streamlit/                # Dashboard application
│       ├── main.py              # Main dashboard
│       ├── app_utils.py         # Utility functions
│       └── snowflake.png        # Assets
├── requirements.txt              # Python dependencies
└── README.md                    # This file
```

## Setup

### Prerequisites

- Snowflake account with access to ACCOUNTADMIN privilege to create user and roles.
- Snowflake CLI (latest version)
- Python 3.9+ 
- Streamlit
- Git

### Installation

(Assumes local setup)

1. **Clone this repo**
    ```bash
    git clone <git url>
    ```
    
2. **Install Python Dependencies**
   ```bash
   uv venv
   source .venv/bin/activate
   uv pip install -r requirements.txt
   ```
   
   > See [`requirements.txt`](requirements.txt) for the complete list of dependencies.

3. **Setup Snowflake Infrastructure**
   
   3.1 Create service user and role :
   
   - Use the script [`00_roles.sql`](src/sql/00_roles.sql)* to create role for dbt Projects service account 
   ```bash
   cd src/sql
   snow sql --connection <named connection in TOML> -f 00_roles.sql
   ```   
   ⚠️ NOTE
   > This will need a user with ACCOUNTADMIN privilege assigned.
   > As a better authentication practice the script will create a PAT for the service user and tie it to the role created above. This command is last to execute and so the output of this command is the only place where the token appears. Copy the token from the output for use when authenticating to an endpoint.
   
   3.2 Generate a key-pair for this user following the steps [here](https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-authentication) and `ALTER USER` to update the public key.

   3.3 Update the environment variables and generate required YAML files

      3.3.1. Configure all variable in the `.env` file using the [`.env.template`](.env.template)
   
      3.3.2. Generate snowflake.yml file for use with Snowflake CLI 
         ```bash
         cd src/scripts
         ./create_snowflake_yaml.sh -e <path to .env file>
         ```
         Verify that the snowflake.yml is created under `sql` dir
      
      3.3.3. Generate profile.yml file for creating the dbt Project
           ```bash
         cd src/scripts
         ./create_profiles_yml.sh -e <path to .env file>


   3.3 Grant usage on the `GIT API INTEGRATION` and `EXTERNAL_ACCESS_INTEGRATION` objects configured in the env file to the user above.
   
   3.4 Run the setup script to create necessary Snowflake objects:
    
   ```bash
   cd src/scripts
   ./sqlsetup.sh -e ../path/to/your/.env
   ```
   
   This script will:
   - Execute [`01_before_slack_connector.sql`](src/sql/01_before_slack_connector.sql) to create initial database structure
   - Execute [`02_orchestration.sql`](src/sql/02_orchestration.sql) to set up dbt Projects orchestration components

4. **Load sample data** (optional)
    - Load sample CSV data for each of the tables using the Snowsight table loader UI.

5. **Verify Setup**
   - Check that Snowflake objects were created successfully
   - Test Streamlit connectivity by running the dashboard
   - Verify dbt models compile and run correctly

### Setup Slack Connector (OpenFlow)

Follow the [official Snowflake documentation](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup) to configure a Slack app and set up the OpenFlow Slack connector.

 > ⚠️ Best Practice
- Create a dedicated SERVICE account for the Slack app
- Use Key-Pair authentication with an *encrypted* private key
- Configure appropriate channel permissions for incident reporting

## General Usage

### Running the Dashboard

1. **Start the Streamlit Application**
   ```bash
   cd src/streamlit
   streamlit run main.py
   ```
   
   > See [`main.py`](src/streamlit/main.py) for the complete dashboard implementation.

2. **Access the Dashboard**
   - Open your browser to `http://localhost:8501`
   - The dashboard will display real-time incident metrics, trends, and detailed tables

### Dashboard Features

- **Metrics Overview**: Critical, high-priority, active, and recently closed incident counts
- **Active Incidents Table**: Real-time view of open incidents with priority indicators
- **Recently Closed Incidents**: Track resolution times and outcomes
- **Attachment Viewer**: Click on incidents with attachments to view images
- **Trend Analysis**: Monthly and weekly incident patterns (when data is available)

### Managing Incidents via Slack

1. **Report New Incidents**: Post messages in configured Slack channels
2. **Automatic Processing**: The system will:
   - Extract incident details from messages
   - Classify incident type and priority using AI
   - Process attached images for additional context
   - Create structured incident records
3. **Track Progress**: Monitor incidents through the Streamlit dashboard

## Additional Resources

- [Snowflake AI Functions Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [OpenFlow Connectors](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/about-openflow-connectors)

---

## Questions, Feedback, and Contribution
Please feel free to reach out with any questions to chinmayee.lakkad@snowflake.com

Feedback and contributions are very welcome:

- GitHub Issues for bug reports and feature requests
- Pull Requests for direct contributions

---
