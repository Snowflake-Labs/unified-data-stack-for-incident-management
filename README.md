
## Table of Contents
- [An Unified Data Stack on Snowflake](#an-unified-data-stack-on-snowflake)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Demo Vignettes](#demo-vignettes)
  - [1. OpenFlow-Based Slack Ingestion](#1-openflow-based-slack-ingestion)
  - [2. dbt Projects on Snowflake](#2-dbt-projects-on-snowflake)
  - [3. AI/SQL Integration within dbt Models](#3-aisql-integration-within-dbt-models)
    - [Unstructured Text Processing](#unstructured-text-processing)
    - [Image Processing](#image-processing)
  - [4. Streamlit Integration](#4-streamlit-integration)
  - [5. End-to-End Workflow Example](#5-end-to-end-workflow-example)
- [Data Models](#data-models)
  - [Landing Zone](#landing-zone)
  - [Curated Zone](#curated-zone)
- [Project Structure](#project-structure)
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites-1)
    - [Installation Steps](#installation-steps)
    - [Makefile Usage Reference](#makefile-usage-reference)
- [General Usage](#general-usage)
  - [Running the Dashboard](#running-the-dashboard)
  - [Dashboard Features](#dashboard-features)
  - [Managing Incidents via Slack](#managing-incidents-via-slack)
- [Additional Resources](#additional-resources)
- [Questions, Feedback, and Contribution](#questions-feedback-and-contribution)


# An Unified Data Stack on Snowflake

*This project demonstrates a modern data stack for an example real-life situation that of incident management that typically requires multiple steps, and close collaboration between representatives using tools like Slack. This project uses a modern stack with Snowflake to bring AI-powered automation and real-time analytics to this known business process that can benefit from AI inclusion.*


An end-to-end incident management platform* built on Snowflake that demonstrates modern data engineering practices using dbt, AI/ML capabilities, and real-time visualization through Streamlit. The system ingests incident data from Slack via Snowflake's OpenFlow connector and provides intelligent categorization, tracking, and reporting capabilities.

*a small cross-section of a much larger process to show the art of possible 


## Architecture

```
┌─────────────────┐    ┌──────────────┐         ┌─────────────────┐
│   Slack App     │───▶│   OpenFlow   │────────▶│   Snowflake     │
│                 │    │  Connector   │         |    Landing Zone │
└─────────────────┘    └──────────────┘         └─────────────────┘
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
- [`bronze_zone.incidents`](src/incident_management/models/bronze_zone/incidents.sql): AI-enhanced incident processing with image analysis
- [`gold_zone.active_incidents`](src/incident_management/models/gold_zone/active_incidents.sql): Business-ready incident tracking

### 3. AI/SQL Integration within dbt Models

**Scenario**: Intelligent incident classification and processing

#### Unstructured Text Processing
```sql
-- Automatic incident categorization from Slack messages
ai_classify(sri.text, ['payment gateway error', 'login error', 'other']):labels[0] as category

-- Smart incident matching using natural language
ai_filter(
  prompt('The text category {0} is logically relatable to this record\'s categoßry {1}', 
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

> See the complete implementation in [`incidents.sql`](src/incident_management/models/bronze_zone/incidents.sql)

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
- [`incidents`](src/incident_management/models/bronze_zone/incidents.sql): Core incident records with AI-powered classification
- [`incident_comment_history`](src/incident_management/models/bronze_zone/incident_comment_history.sql): Chronological updates and comments
- [`incident_attachments`](src/incident_management/models/bronze_zone/incident_attachments.sql): File attachments with metadata (as ingested from Slack)
- [`users`](src/incident_management/models/bronze_zone/users.sql): User directory for assignees and reporters

### Curated Zone
- [`active_incidents`](src/incident_management/models/gold_zone/active_incidents.sql): Currently open incidents with enriched data
- [`closed_incidents`](src/incident_management/models/gold_zone/closed_incidents.sql): Resolved incidents with resolution metrics
- [`weekly_incident_trends`](src/incident_management/models/gold_zone/weekly_incident_trends.sql): Weekly trend analysis


## Project Structure

```
unified-data-stack-for-incident-management/
├── data/                          # Sample data and test files
│   ├── csv/                       # CSV seed data
│   │   ├── incident_comment_history.csv
│   │   ├── incidents.csv
│   │   ├── slack_conversation_history.csv
│   │   └── users.csv              # User directory
│   ├── docs/
│   │   └── Global INM Policy.docx
│   ├── exports/
│   │   ├── incm_quaterly_review_metrics_2024_Q1.pptx
│   │   ├── incm_quaterly_review_metrics_2024_Q2.pptx
│   │   ├── incm_quaterly_review_metrics_2024_Q3.pptx
│   │   ├── incm_quaterly_review_metrics_2024_Q4.pptx
│   │   ├── incm_quaterly_review_metrics_2025_Q1.pptx
│   │   └── incm_quaterly_review_metrics_2025_Q2.pptx
│   └── images/                    # Sample incident attachments
│       ├── invalid_credentials.jpeg
│       └── payment_gateway_outage.jpeg
├── screenshots/
│   ├── destination_params.png
│   └── snowflake_role_params.png
├── src/
│   ├── incident_management/      # dbt project
│   │   ├── models/
│   │   │   ├── bronze_zone/      # Raw staging/views
│   │   │   │   ├── users.sql
│   │   │   │   ├── v_qualify_new_documents.sql
│   │   │   │   └── v_qualify_slack_messages.sql
│   │   │   ├── gold_zone/        # Analytics-ready models
│   │   │   │   ├── active_incidents.sql
│   │   │   │   ├── closed_incidents.sql
│   │   │   │   ├── incident_attachments.sql
│   │   │   │   ├── incident_comment_history.sql
│   │   │   │   ├── incidents.sql
│   │   │   │   └── weekly_incident_trends.sql
│   │   │   └── sources.yml       # Source definitions and tests
│   │   ├── macros/               # Custom dbt macros
│   │   │   ├── clean_stale_documents.sql
│   │   │   └── generate_schema_name.sql
│   │   ├── dbt_project.yml       # dbt configuration
│   │   ├── packages.yml
│   │   └── profiles.yml          # Database connections
│   ├── scripts/                  # Deployment and setup scripts
│   │   ├── create_snowflake_yaml.sh # Generate snowflake.yml from template
│   │   ├── dbtdeploy.sh         # dbt deployment automation
│   │   ├── dbtexec.sh           # dbt execution wrapper
│   │   └── snowflake.yml.template
│   ├── sql/                      # Raw SQL scripts
│   │   ├── 01_dbt_projects_stack.sql # dbt Projects infrastructure setup
│   │   ├── 02_slack_connector.sql    # Slack connector setup
│   │   └──                     
│   └── streamlit/               # Dashboard application
│       ├── main.py              # Main dashboard
│       ├── app_utils.py         # Utility functions
│       └── snowflake.png        # Assets
├── Makefile
├── requirements.txt             # Python dependencies
└── README.md                    # This file
```

## Setup

### Prerequisites

- Snowflake account with access to ACCOUNTADMIN privilege to create user and roles
- Snowflake CLI (latest version)
- *Openflow SPCS deployment and a Small runtime
- Git
- [uv](https://docs.astral.sh/uv/getting-started/installation/) for Python virtual environment and dependency management

### Installation

This project demonstrates dbt Projects deployment and execution from local dev machine. But once deployed, it is easy to switch to Snowflake Workspaces to manage further redeployments and test executions.

#### Prerequisites

Before starting the installation, ensure you have:
- **Snowflake CLI** installed ([installation guide](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation))
- **Snowflake connection** configured in `~/.snowflake/config.toml`
- **ACCOUNTADMIN privileges** in your Snowflake account
- **Openflow SPCS** Use these installation [instructions](https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs) to setup Openflow SPCS deployment and a runtime on top within your Snowflake account

#### Installation Steps

1. **Clone this repo**

   ```bash
   git clone https://github.com/Snowflake-Labs/unified-data-stack-for-incident-management.git
   cd unified-data-stack-for-incident-management
   ```

2. **Configure Environment Variables**

   Copy the template and configure your environment:
   ```bash
   cp env.template .env
   ```
   
   Edit `.env` file and configure all variables except these two (generated later):
   - `DBT_SNOWFLAKE_PASSWORD`
   - `DBT_SNOWFLAKE_PRIVATE_KEY_PATH`

   > **Note:** If you change any of the below parameters, be sure to change the profiles.yml as well
      - `DBT_PROJECT_DATABASE=incident_management`
      - `DBT_PROJECT_SCHEMA=dbt_project_deployments`
      - `MODEL_SCHEMA=bronze_zone`
      - `DBT_SNOWFLAKE_WAREHOUSE=incident_management_dbt_wh`
      - `DBT_PROJECT_ADMIN_ROLE=dbt_projects_engineer`

3. **Setup Snowflake Infrastructure (Automated)**

   Use the Makefile to automate the entire Snowflake setup:

   **Option A: Complete Setup (Recommended)**
   ```bash
   # Run complete installation
   make install ENV_FILE=.env CONN=<your-connection-name>
   ```

   **Option B: Step-by-Step Setup**
   ```bash
   # Step 2.1: Generate snowflake.yml configuration
   make generate-yaml ENV_FILE=.env
   
   # Step 2.2: Setup dbt Projects infrastructure
   make setup-dbt-stack CONN=<your-connection-name>
   
   # Step 2.3: Setup Slack connector infrastructure
   make setup-slack-connector CONN=<your-connection-name>
   ```

   > **Note:** Replace `<your-connection-name>` with the connection name defined in your `~/.snowflake/config.toml`

   > **Note:** Role setup commands require ACCOUNTADMIN privileges

4. **Setup User Authentication (Optional)**

   Execute this step if planning to run Streamlit app remotely and/or deploy dbt Projects remotely:
   
   a. **Generate PAT Token**: From Snowsight UI generate a PAT for the dbt Projects service user tied to the role created in previous step. Note and copy the token for use during authentication.
   
   b. **Generate Key-Pair Authentication**: Follow the steps [here](https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-authentication):
      ```bash
      # Generate private and public key
      openssl genrsa -out rsa_private_key.pem 2048
      openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem
      ```
      
      Then update the user in Snowflake (replace placeholder):
      ```sql
      ALTER USER <user name> SET RSA_PUBLIC_KEY='
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAA...
      -----END PUBLIC KEY-----';
      ```
   
   c. **Update Environment Variables**: Update `.env` with:
      - `DBT_SNOWFLAKE_PASSWORD=<your-PAT-token>`
      - `DBT_SNOWFLAKE_PRIVATE_KEY_PATH=<path-to-private-key-file>`

5. **Configure Slack Connector (Post-Installation)**

   After running the Makefile setup, configure the Slack connector in your OpenFlow SPCS runtime:
   
   a. **Review Prerequisites**: Check the [pre-requisites](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#prerequisites)
   
   b. **Create Slack App**: Create a Slack app in your workspace using the given [manifest](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#set-up-a-slack-app)
   
   c. **Update External Access**: [Update](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#setup-necessary-ingress-rules) the External Access Integration object to add `slack.com` domain for egress from SPCS containers
   
   d. **Configure Connector**: Use these [instructions](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#configure-the-connector) to configure the connector. Ensure to use the database and role parameters created by the Makefile:
   
      ![Destination Parameters](screenshots/destination_params.png)
      ![Snowflake Role Parameters](screenshots/snowflake_role_params.png)
   
   e. **Start and Test**: Start the connector and add the Slack app to a channel. Verify these tables are created:
      - `SLACK_MEMBERS`, `SLACK_MEMBERS_STAGING`
      - `DOC_METADATA`, `FILE_HASHES`, `SLACK_MESSAGES`

6. **Test the Setup**

   Drop a test message in your Slack channel and verify that a record appears in the `SLACK_MESSAGES` table (might take a few seconds).

#### Makefile Usage Reference

For detailed information about available Makefile targets:
```bash
make help
```

**Common Commands:**
```bash
# Check prerequisites
make check-prereqs

# Complete automated setup
make install ENV_FILE=.env CONN=myconnection

# Individual steps
make generate-yaml ENV_FILE=.env
make setup-dbt-stack CONN=myconnection  
make setup-slack-connector CONN=myconnection
```

**Troubleshooting:**
- Ensure your Snowflake connection is properly configured in `~/.snowflake/config.toml`
- Verify you have ACCOUNTADMIN privileges
- Check that all environment variables are set in your `.env` file
- Run `make check-prereqs` to verify prerequisites

## General Usage

### Running the Dashboard

1. **Start the Streamlit Application**

   1.1 Install Python Dependencies
   ```bash
   uv venv
   source .venv/bin/activate
   uv pip install -r requirements.txt
   ```
   
   > See [`requirements.txt`](requirements.txt) for the complete list of dependencies.

   1.2 Now run the Streamlit app locally
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
