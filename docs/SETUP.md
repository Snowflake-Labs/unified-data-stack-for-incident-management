# Installation & Setup Guide

This guide walks you through setting up the Incident Management platform on Snowflake.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [User Authentication Setup](#user-authentication-setup)
- [Slack Connector Configuration](#slack-connector-configuration)
- [Streamlit Dashboard](#streamlit-dashboard)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the installation, ensure you have:

- **Snowflake CLI** installed ([installation guide](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation))
- **Snowflake connection** configured in `~/.snowflake/config.toml`
- **ACCOUNTADMIN privileges** in your Snowflake account
- **Openflow SPCS** deployment and runtime. Use these [installation instructions](https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs) to set up OpenFlow SPCS within your Snowflake account

## Installation Steps

This project demonstrates dbt Projects deployment and execution from a local dev machine. Once deployed, you can switch to Snowflake Workspaces to manage further redeployments and test executions.

### 1. Fork and Clone the Repository

```bash
git clone https://github.com/Snowflake-Labs/unified-data-stack-for-incident-management.git
cd unified-data-stack-for-incident-management
git remote add upstream https://github.com/ORIGINAL_OWNER/REPO_NAME.git
git remote -v
```

### 2. Configure Environment Variables

Copy the template and configure your environment:

```bash
cp .env.template .env
```

Edit the `.env` file and configure all variables except these two (generated later):
- `DBT_SNOWFLAKE_PASSWORD`
- `DBT_SNOWFLAKE_PRIVATE_KEY_PATH`

> **Note:** If you change any of the below parameters, be sure to change the `profiles.yml` as well:
> - `DBT_PROJECT_DATABASE=v1_incident_management`
> - `DBT_PROJECT_SCHEMA=dbt_project_deployments`
> - `MODEL_SCHEMA=bronze_zone`
> - `DBT_SNOWFLAKE_WAREHOUSE=v1_demo_wh`
> - `DBT_PROJECT_ADMIN_ROLE=dbt_projects_engineer`

### 3. Setup Snowflake Infrastructure

Use the Makefile to automate the entire Snowflake setup.

#### Option A: Complete Setup (Recommended)

```bash
# Run complete installation
make install ENV_FILE=.env CONN=<your-connection-name>
```

#### Option B: Step-by-Step Setup

For detailed information about available Makefile targets:

```bash
make help
```

Run each step individually:

```bash
# Step 1: Generate snowflake.yml configuration
make generate-yaml ENV_FILE=.env

# Step 2: Setup dbt Projects infrastructure
make setup-dbt-stack CONN=<your-connection-name>

# Step 3: Setup Slack connector infrastructure
make setup-slack-connector CONN=<your-connection-name>
```

> **Note:** Replace `<your-connection-name>` with the connection name defined in your `~/.snowflake/config.toml`

> **Important:** Role setup commands require ACCOUNTADMIN privileges

## User Authentication Setup

Execute this step if planning to run the Streamlit app remotely and/or deploy dbt Projects remotely.

### 1. Generate PAT Token

From Snowsight UI, generate a PAT (Personal Access Token) for the dbt Projects service user tied to the role created in the previous step. Note and copy the token for use during authentication.

### 2. Generate Key-Pair Authentication

Follow the steps in the [Snowflake documentation](https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-authentication):

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

### 3. Update Environment Variables

Update your `.env` file with:
- `DBT_SNOWFLAKE_PASSWORD=<your-PAT-token>`
- `DBT_SNOWFLAKE_PRIVATE_KEY_PATH=<path-to-private-key-file>`

## Slack Connector Configuration

After running the Makefile setup, configure the Slack connector in your OpenFlow SPCS runtime.

### 1. Review Prerequisites

Check the [pre-requisites](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#prerequisites) for the Slack connector.

### 2. Create Slack App

Create a Slack app in your workspace using the given [manifest](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#set-up-a-slack-app).

### 3. Generate App Token

While creating your Slack app, ensure to generate the App token using at least the below scope:
- `connections:write`

### 4. Update External Access in Snowflake

[Update](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#setup-necessary-ingress-rules) the External Access Integration object to add `slack.com` domain for egress from SPCS containers.

### 5. Configure Connector in OpenFlow Runtime Canvas

Use these [instructions](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/slack/setup#configure-the-connector) to configure the connector. Ensure to use the database and role parameters created by the Makefile:

![Destination Parameters](../screenshots/destination_params.png)
![Snowflake Role Parameters](../screenshots/snowflake_role_params.png)

### 6. Start and Test

Start the connector and add the Slack app to a channel. Verify these tables are created:
- `SLACK_MEMBERS`
- `SLACK_MEMBERS_STAGING`
- `DOC_METADATA`
- `FILE_HASHES`
- `SLACK_MESSAGES`

### 7. Test Message Ingestion

Drop a test message in your Slack channel and verify that a record appears in the `SLACK_MESSAGES` table (might take a few seconds).

## Streamlit Dashboard

### Accessing the Dashboard

After completing the setup, a Streamlit in Snowflake (SiS) app will be deployed to your Snowflake account. This enables you to run through foundational scenarios end-to-end.

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

## Troubleshooting

### Common Issues

**Connection Issues**
- Ensure your Snowflake connection is properly configured in `~/.snowflake/config.toml`
- Verify you have ACCOUNTADMIN privileges
- Check that all environment variables are set in your `.env` file

**Prerequisites Check**
```bash
make check-prereqs
```

**Slack Connector Not Working**
- Verify the Slack app has the correct scopes
- Check that External Access Integration includes `slack.com`
- Ensure the connector is running in OpenFlow runtime
- Verify table creation in Snowflake

**dbt Project Deployment Issues**
- Confirm authentication is properly configured
- Check that the warehouse and role exist
- Review `profiles.yml` for correct connection settings

For more detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Next Steps

- Review the [Architecture Documentation](ARCHITECTURE.md) to understand the system design
- Explore [Demo Vignettes](DEMOS.md) to see the platform in action
- Check out the [Reference Material](#reference-material) for additional resources

## Reference Material

- [Snowflake AI Functions Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [OpenFlow Connectors](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/about-openflow-connectors)

