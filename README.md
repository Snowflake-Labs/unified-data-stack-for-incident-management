
# What's included?

1. dbt (core) project that you can setup locally
   1.1 Contains AISQL to process unstructured text or images as coming in through Slack
2. Two-page Streamlit app 
   2.1. Display metrics dashboard
   2.2 Image comparison and retrieval
3. SQL scripts that are run on server side (on your Snowflake account)
4. Shell scripts 
   4.1 Deploy local dbt models to dbt Project on Snowflake using snow cli

# What's not included (and requires setup outside this)

1. Openflow Slack connector setup - You can use this documentation to setup a Slack app that's deployed in your Slack workspace 

# Storytelling

## The scenario
FWIP

## Vignettes
FWIP

# Setup

## DBT Profiles Configuration with Environment Variables

The `profiles.yml` file has been updated to use environment variables for better security and flexibility. This approach allows you to:

- Keep sensitive credentials out of version control
- Easily switch between different environments
- Configure settings without modifying the profiles.yml file

### Required Environment Variables

The following environment variables **must** be set before running dbt:

| Variable | Description | Example |
|----------|-------------|---------|
| `DBT_SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier | `abc12345` |
| `DBT_SNOWFLAKE_USER` | Snowflake username | `your_service_usr` |
| `DBT_SNOWFLAKE_PRIVATE_KEY_PATH` | Path to your private key file | `/Users/path/to/private/key.p8` |

### Optional Environment Variables 

| Variable | Description |
|----------|-------------|
| `DBT_SNOWFLAKE_DATABASE` | Database name for dev |
| `DBT_SNOWFLAKE_ROLE`  | Role for dev environment |
| `DBT_SNOWFLAKE_SCHEMA`  | Schema for dev environment |
| `DBT_SNOWFLAKE_WAREHOUSE`  | Warehouse for dev |
| `DBT_SNOWFLAKE_DATABASE_PROD`  | Database name for prod |
| `DBT_SNOWFLAKE_ROLE_PROD` | Role for prod environment |
| `DBT_SNOWFLAKE_SCHEMA_PROD`  | Schema for prod environment |
| `DBT_SNOWFLAKE_WAREHOUSE_PROD` | Warehouse for prod |
| `DBT_TARGET`  | Default target environment |
| `DBT_THREADS`  | Number of threads |


### Exporting local environment variables 

1. **Copy the template file**:
   ```bash
   cp .env.template .env
   ```

2. **Edit the .env file** with your actual values

3. **Run the setup script**:
   ```bash
   source .env
   ```

4. **Test the configuration**:
   ```bash
   dbt debug
   ```

