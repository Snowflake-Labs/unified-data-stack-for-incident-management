#!/usr/bin/env bash

# Usage: ./execute.sh <dbt_command> [additional_options]
# Examples:
#   ./execute.sh compile
#   ./execute.sh run
#   ./execute.sh test --select my_model
#   ./execute.sh run --full-refresh

# Function to show help
show_help() {
    echo "Usage: $0 <dbt_command> [additional_options]"
    echo ""
    echo "Description:"
    echo "  Execute dbt commands using Snowflake CLI with predefined connection settings"
    echo ""
    echo "Arguments:"
    echo "  dbt_command      Required. The dbt command to execute (e.g., compile, run, test)"
    echo "  additional_options  Optional. Additional dbt options and flags"
    echo ""
    echo "Examples:"
    echo "  $0 compile"
    echo "  $0 run"
    echo "  $0 test"
    echo "  $0 run --select my_model"
    echo "  $0 run --full-refresh"
    echo "  $0 test --select tag:critical"
    echo ""
    echo "Environment Variables Required:"
    echo "  SNOWFLAKE_USER     - Snowflake CLI connection name"
    echo "  DBT_PROJECT_DATABASE    - Target database name"
    echo "  DBT_PROJECT_SCHEMA      - Target schema name"
    echo "  DBT_PROJECT_NAME        - dbt project name"
    echo ""
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    show_help
    exit 0
fi

# Check if dbt command is provided
if [[ $# -eq 0 ]]; then
    echo "Error: No dbt command provided"
    echo ""
    show_help
    exit 1
fi

# Check required environment variables
required_vars=("SNOWFLAKE_USER" "DBT_PROJECT_DATABASE" "DBT_PROJECT_SCHEMA" "DBT_PROJECT_NAME")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Get the dbt command and additional options
DBT_COMMAND="$1"
shift  # Remove the first argument, leaving any additional options
ADDITIONAL_OPTIONS="$@"

# Construct and execute the snow dbt command
SNOW_DBT_CMD="snow dbt execute --connection $SNOWFLAKE_USER $DBT_PROJECT_DATABASE.$DBT_PROJECT_SCHEMA.$DBT_PROJECT_NAME $DBT_COMMAND $ADDITIONAL_OPTIONS"

echo "Executing: $SNOW_DBT_CMD"
echo ""

# Execute the command
eval "$SNOW_DBT_CMD" 