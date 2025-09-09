#! /usr/bin/env bash

# Usage: ./deploy_dbt.sh [force|refresh] [env_file_path]
# force   - Deploy new dbt project with --force flag
# refresh - Deploy existing dbt project without --force flag
# env_file_path - Optional path to custom environment file (defaults to ../.env)

# Default environment file
DEFAULT_ENV_FILE="../../.env"

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [force|refresh] [env_file_path]"
    echo "  force         - Deploy new dbt project with --force flag"
    echo "  refresh       - Deploy existing dbt project without --force flag"
    echo "  env_file_path - Optional path to custom environment file (defaults to ../.env)"
    echo ""
    echo "Examples:"
    echo "  $0 force"
    echo "  $0 refresh"
    echo "  $0 force ../my_custom.env"
    echo "  $0 refresh /path/to/production.env"
    exit 1
fi

# Validate first argument (deploy type)
DEPLOY_TYPE=$1
if [ "$DEPLOY_TYPE" != "force" ] && [ "$DEPLOY_TYPE" != "refresh" ]; then
    echo "Error: Invalid deploy type '$DEPLOY_TYPE'"
    echo "Usage: $0 [force|refresh] [env_file_path]"
    echo "  force         - Deploy new dbt project with --force flag"
    echo "  refresh       - Deploy existing dbt project without --force flag"
    echo "  env_file_path - Optional path to custom environment file (defaults to ../.env)"
    exit 1
fi

# Set environment file path
if [ $# -ge 2 ]; then
    ENV_FILE=$2
else
    ENV_FILE=$DEFAULT_ENV_FILE
fi

# Validate environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    exit 1
fi

echo "Using environment file: $ENV_FILE"
source "$ENV_FILE"

# Validate all required environment variables are set
echo "Validating required environment variables..."

# First check basic required variables
BASIC_REQUIRED_VARS=(
    "DBT_PROJECT_NAME"
    "DBT_PROJECT_DIR"
    "DBT_PROFILES_DIR"
    "DBT_TARGET"
    "SNOW_CLI_CONNECTION"
    "DBT_PROJECT_DATABASE"
    "DBT_PROJECT_SCHEMA"
    "DBT_PROJECT_ADMIN_ROLE"
    "DBT_SNOWFLAKE_WAREHOUSE"
)

MISSING_VARS=()

for var in "${BASIC_REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "Error: The following required environment variables are not set or empty:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please ensure these variables are properly defined in your environment file: $ENV_FILE"
    exit 1
fi

echo "All required environment variables are set ✓"

# Validate DBT_PROJECT_DIR exists
if [ ! -d "$DBT_PROJECT_DIR" ]; then
    echo "Error: DBT project directory '$DBT_PROJECT_DIR' does not exist"
    exit 1
fi

echo "DBT project directory exists ✓"

## Refresh local Git repo for the dbt Project
echo "Refreshing Git repository..."
cd "$DBT_PROJECT_DIR"
git pull

## Deploy the dbt project to Snowflake
echo "Deploying dbt project with $DEPLOY_TYPE mode for target: $DBT_TARGET..."

# Display environment variables (excluding sensitive information)
echo "=== Deployment Configuration ==="
echo "Project Name: $DBT_PROJECT_NAME"
echo "Project Directory: $DBT_PROJECT_DIR"
echo "Profiles Directory: $DBT_PROFILES_DIR"
echo "Target: $DBT_TARGET"
echo "Connection: $SNOW_CLI_CONNECTION"
echo "Database: $DBT_PROJECT_DATABASE"
echo "Schema: $DBT_PROJECT_SCHEMA"
echo "Role: $DBT_PROJECT_ADMIN_ROLE"
echo "Warehouse: $DBT_SNOWFLAKE_WAREHOUSE"
echo "Deploy Type: $DEPLOY_TYPE"
if [ "$DEPLOY_TYPE" = "force" ]; then
    echo "Authentication: SNOWFLAKE_JWT (using private key)"
else
    echo "Authentication: Password-based"
fi
echo "================================="
echo ""

if [ "$DEPLOY_TYPE" = "force" ]; then
    # Validate private key file exists for JWT authentication
    if [ -z "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH" ] || [ ! -f "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH" ]; then
        echo "Error: Private key file not found or DBT_SNOWFLAKE_PRIVATE_KEY_PATH not set"
        echo "Required for force deployment with JWT authentication"
        exit 1
    fi
    
    echo "Deploying new dbt project with --force flag using SNOWFLAKE_JWT authentication"

    # Deploy new dbt project with --force flag
    snow dbt deploy $DBT_PROJECT_NAME \
        --source $DBT_PROJECT_DIR \
        --profiles-dir $DBT_PROFILES_DIR \
        --connection $SNOW_CLI_CONNECTION \
        --force \
        --database "$DBT_PROJECT_DATABASE" \
        --schema "$DBT_PROJECT_SCHEMA" \
        --role "$DBT_PROJECT_ADMIN_ROLE" \
        --warehouse "$DBT_SNOWFLAKE_WAREHOUSE" \
        --authenticator SNOWFLAKE_JWT \
        --private-key-file "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH"
else
    # Validate password is set for password authentication
    if [ -z "$DBT_SNOWFLAKE_PASSWORD" ]; then
        echo "Error: DBT_SNOWFLAKE_PASSWORD not set"
        echo "Required for refresh deployment with password authentication"
        exit 1
    fi

    echo "Deploying existing dbt project without --force flag using password authentication"
    
    # Deploy existing dbt project without --force flag
    snow dbt deploy $DBT_PROJECT_NAME \
        --source $DBT_PROJECT_DIR \
        --profiles-dir $DBT_PROFILES_DIR \
        --connection $SNOW_CLI_CONNECTION \
        --database "$DBT_PROJECT_DATABASE" \
        --schema "$DBT_PROJECT_SCHEMA" \
        --role "$DBT_PROJECT_ADMIN_ROLE" \
        --warehouse "$DBT_SNOWFLAKE_WAREHOUSE" \
        --password "$DBT_SNOWFLAKE_PASSWORD"
fi

echo ""

