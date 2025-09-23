# This script executes SQL scripts to set up and configure the incident management system in Snowflake
#
# It performs the following:
# 1. Generates snowflake.yml configuration file from template using environment variables
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
# Basic usage with default .env:
#   ./sqlsetup.sh
#
# Use custom environment file:
#   ./sqlsetup.sh -e prod.env
#



#!/usr/bin/env bash

# Default environment file
ENV_FILE=".env"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --env FILE        Environment file to use (default: .env)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Uses default .env file"
            echo "  $0 -e prod.env           # Uses prod.env file"
            echo "  $0 --env dev.env         # Uses dev.env file"
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

# Function to generate snowflake.yml from template
generate_snowflake_yml() {
    local template_file="snowflake.yml.template"
    local output_file="snowflake.yml"
    
    if [ ! -f "$template_file" ]; then
        echo "Warning: Template file '$template_file' not found, skipping snowflake.yml generation"
        return 1
    fi
    
    echo "Generating $output_file from $template_file..."
    
    # Read template and substitute environment variables
    while IFS= read -r line; do
        # Replace ${VAR_NAME} patterns with actual environment variable values
        while [[ $line =~ \$\{([^}]+)\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${!var_name}"
            
            if [ -z "$var_value" ]; then
                echo "Warning: Environment variable '$var_name' is not set"
                var_value=""
            fi
            
            line="${line/\${$var_name}/$var_value}"
        done
        echo "$line"
    done < "$template_file" > "$output_file"
    
    echo "Successfully generated $output_file"
    return 0
}

# Generate snowflake.yml configuration file from template
generate_snowflake_yml

snow sql \
--connection $SNOW_CLI_CONNECTION \
-f "../sql/00_roles.sql" 

# Execute database objects SQL (uncommented and updated)
snow sql \
--connection $SNOW_CLI_CONNECTION \
-f "../sql/01_before_slack_connector.sql"

snow sql \
--connection $SNOW_CLI_CONNECTION \
-f "../sql/02_orchestration.sql"