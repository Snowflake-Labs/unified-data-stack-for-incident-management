#! /usr/bin/env bash

# Usage: ./deploy.sh [env_file_path]
# env_file_path - Optional path to custom environment file (defaults to ../.env)
#
# This script clones the git repository into a temporary directory for deployment.
# Required environment variables:
#   GIT_REPOSITORY_URL - Git repository URL to clone

# Default environment file
DEFAULT_ENV_FILE="../../.env"

# Show usage if help is requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [env_file_path]"
    echo "  env_file_path - Optional path to custom environment file (defaults to ../../.env)"
    echo ""
    echo "This script clones a git repository into a temporary directory for deployment."
    echo "Required environment variables in your .env file:"
    echo "  GIT_REPOSITORY_URL - Git repository URL to clone"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 ../my_custom.env"
    echo "  $0 /path/to/production.env"
    exit 0
fi

# Set environment file path
if [ $# -ge 1 ]; then
    ENV_FILE=$1
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
    "GIT_REPOSITORY_URL"
    "DBT_TARGET"
    "SNOWFLAKE_USER"
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

# Create temporary directory for git clone
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Set up cleanup function to remove temporary directory on exit
cleanup() {
    echo "Cleaning up temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Clone the git repository
echo "Cloning git repository: $GIT_REPOSITORY_URL (branch: main)"
git clone --branch main --single-branch "$GIT_REPOSITORY_URL" "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone git repository"
    exit 1
fi

echo "Git repository cloned successfully ✓"

# Set DBT_PROJECT_DIR to the subdirectory within the cloned repo
DBT_PROJECT_DIR="$TEMP_DIR/$REPO_DBT_PROJECTS_YML_PATH"


echo "DBT project directory exists: $DBT_PROJECT_DIR ✓"

## Replace environment variables in configuration files
echo "Replacing environment variables in configuration files..."

# Function to replace environment variables in files
replace_env_vars() {
    local file_path="$1"
    local temp_file="${file_path}.tmp"
    
    if [ -f "$file_path" ]; then
        echo "  Processing: $file_path"
        
        # Replace dbt Jinja env_var patterns: {{ env_var('VAR_NAME') }} and {{ env_var('VAR_NAME', default) }}
        # Process line by line to handle the Jinja template replacements
        
        # Process each line to handle env_var replacements
        while IFS= read -r line; do
            original_line="$line"
            
            # Keep processing until no more env_var patterns are found
            while [[ $line =~ \{\{[[:space:]]*env_var\([[:space:]]*\'([^\']+)\'([^}]*)\}\} ]]; do
                local full_match="${BASH_REMATCH[0]}"
                local var_name="${BASH_REMATCH[1]}"
                local remaining="${BASH_REMATCH[2]}"
                local var_value="${!var_name}"
                
                # If variable is not set, try to extract default value
                if [ -z "$var_value" ]; then
                    # Look for default value pattern: , 'default' or , number
                    if [[ $remaining =~ ,[[:space:]]*([^,\)]+) ]]; then
                        local default_part="${BASH_REMATCH[1]}"
                        # Remove leading/trailing whitespace and quotes
                        default_part=$(echo "$default_part" | sed "s/^[[:space:]]*//; s/[[:space:]]*$//")
                        if [[ $default_part =~ ^[\'\"](.*)[\'\"]$ ]]; then
                            var_value="${BASH_REMATCH[1]}"
                        else
                            var_value="$default_part"
                        fi
                        echo "    Using default value '$var_value' for undefined variable '$var_name'"
                    else
                        echo "    Warning: Environment variable '$var_name' is not set and no default provided"
                        var_value=""
                    fi
                fi
                
                # Replace the full pattern with the value
                line="${line//"$full_match"/"$var_value"}"
            done
            
            echo "$line"
        done < "$file_path" > "$temp_file"
        
        # Only replace the original file if processing succeeded
        if [ $? -eq 0 ]; then
            mv "$temp_file" "$file_path"
            echo "    ✓ dbt env_var patterns replaced"
        else
            echo "    ✗ Failed to replace dbt env_var patterns"
            rm -f "$temp_file"
            return 1
        fi
    else
        echo "  Warning: File not found: $file_path"
    fi
}

# List of configuration files that may contain environment variables
CONFIG_FILES=(
    "$DBT_PROJECT_DIR/dbt_project.yml"
    "$DBT_PROJECT_DIR/profiles.yml"
)

# Process each configuration file
for config_file in "${CONFIG_FILES[@]}"; do
    replace_env_vars "$config_file"
done

echo "Environment variable replacement completed ✓"

## Deploy the dbt project to Snowflake
echo "Deploying dbt project with force mode for target: $DBT_TARGET..."

# Display environment variables (excluding sensitive information)
echo "=== Deployment Configuration ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Git Branch: main"
echo "Temporary Directory: $TEMP_DIR"
echo "Project Name: $DBT_PROJECT_NAME"
echo "Project Directory: $DBT_PROJECT_DIR"
echo "Target: $DBT_TARGET"
echo "Connection: $SNOWFLAKE_USER"
echo "Database: $DBT_PROJECT_DATABASE"
echo "Schema: $DBT_PROJECT_SCHEMA"
echo "Role: $DBT_PROJECT_ADMIN_ROLE"
echo "Warehouse: $DBT_SNOWFLAKE_WAREHOUSE"
echo "Deploy Type: force"
echo "Authentication: SNOWFLAKE_JWT (using private key)"
echo "================================="
echo ""

# Validate private key file exists for JWT authentication
if [ -z "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH" ] || [ ! -f "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH" ]; then
    echo "Error: Private key file not found or DBT_SNOWFLAKE_PRIVATE_KEY_PATH not set"
    echo "Required for deployment with JWT authentication"
    exit 1
fi

echo "Deploying dbt project with --force flag using SNOWFLAKE_JWT authentication"

# Deploy dbt project with --force flag
snow dbt deploy $DBT_PROJECT_NAME \
    --source $DBT_PROJECT_DIR \
    --connection $SNOWFLAKE_USER \
    --force \
    --database "$DBT_PROJECT_DATABASE" \
    --schema "$DBT_PROJECT_SCHEMA" \
    --role "$DBT_PROJECT_ADMIN_ROLE" \
    --warehouse "$DBT_SNOWFLAKE_WAREHOUSE" \
    --authenticator SNOWFLAKE_JWT \
    --private-key-file "$DBT_SNOWFLAKE_PRIVATE_KEY_PATH"

echo ""

