# This script executes SQL scripts to set up and configure the incident management system in Snowflake
#
# It performs the following:
# 1. Uses the existing snowflake.yml configuration file from template using environment variables
# 2. Creates necessary databases, warehouses, schemas and tables for incident management
# 3. Sets up dbt project configuration and git integration
# 4. Creates orchestration tasks for automated dbt runs
#
# This script requires the following environment variables to be set in the .env file:
# - DBT_PROJECT_ADMIN_ROLE: Role with admin privileges for dbt project management
# - DBT_PROJECT_DATABASE: Name of the database to create/use for incident management
# - DBT_SNOWFLAKE_WAREHOUSE: Name of the warehouse to create/use
# - DBT_SNOWFLAKE_USER: Username for Snowflake connection
# - GIT_USER_EMAIL: Email address associated with Git repository access
# - GIT_USER_REPO_PAT: Personal access token for Git repository
# - GIT_REPOSITORY_URL: URL of the Git repository containing dbt project
# - SNOWFLAKE_GIT_API_INT: Name of Snowflake's Git API integration
# - EXTERNAL_ACCESS_INTEGRATION: Name of external access integration
#
# Before running:
# 1. Copy .env.template to .env and fill in required values
# 2. Ensure you have appropriate Snowflake access and permissions
#
# Usage examples:
# Basic usage with default .env (runs both SQL scripts):
#   ./sqlsetup.sh
#
# Use custom environment file (runs both SQL scripts):
#   ./sqlsetup.sh -e prod.env
#
# Run only database setup SQL:
#   ./sqlsetup.sh -s
#   ./sqlsetup.sh --setup-only
#
# Run only orchestration SQL:
#   ./sqlsetup.sh -o
#   ./sqlsetup.sh --orchestration-only
#
# Combine environment file with selective execution:
#   ./sqlsetup.sh -e prod.env -s
#   ./sqlsetup.sh -e dev.env --orchestration-only
#



#!/usr/bin/env bash

# Default environment file
ENV_FILE=".env"
RUN_SETUP=true
RUN_ORCHESTRATION=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -s|--setup-only)
            RUN_SETUP=true
            RUN_ORCHESTRATION=false
            shift
            ;;
        -o|--orchestration-only)
            RUN_SETUP=false
            RUN_ORCHESTRATION=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --env FILE        Environment file to use (default: .env)"
            echo "  -s, --setup-only      Run only database setup SQL (01_before_slack_connector.sql)"
            echo "  -o, --orchestration-only  Run only orchestration SQL (02_orchestration.sql)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Uses default .env file, runs both SQL scripts"
            echo "  $0 -e prod.env           # Uses prod.env file, runs both SQL scripts"
            echo "  $0 -s                     # Runs only setup SQL"
            echo "  $0 -o                     # Runs only orchestration SQL"
            echo "  $0 -e prod.env -s        # Uses prod.env and runs only setup SQL"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Using environment file: $ENV_FILE"
source "$ENV_FILE"

# Execute SQL scripts based on flags
if [ "$RUN_SETUP" = true ]; then
    echo "Running database setup SQL..."
    snow sql \
    --connection $SNOW_CLI_CONNECTION \
    -p ../sql \
    -f "../sql/01_before_slack_connector.sql"
fi

if [ "$RUN_ORCHESTRATION" = true ]; then
    echo "Running orchestration SQL..."
    snow sql \
    --connection $SNOW_CLI_CONNECTION \
    -p ../sql \
    -f "../sql/02_orchestration.sql"
fi