#!/usr/bin/env bash

# This script generates profiles.yml configuration file from template using environment variables
#
# Usage examples:
# Basic usage with default .env:
#   ./create_profiles_yml.sh
#
# Use custom environment file:
#   ./create_profiles_yml.sh -e prod.env
#
# Use custom template and output files:
#   ./create_profiles_yml.sh -t custom.template -o custom_profiles.yml
#

# Default values
ENV_FILE=".env"
TEMPLATE_FILE="profiles.yml.template"
OUTPUT_FILE="../incident_management/profiles.yml"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --env FILE        Environment file to use (default: .env)"
            echo "  -t, --template FILE   Template file to use (default: ../incident_management/profiles.yml.template)"
            echo "  -o, --output FILE     Output file to generate (default: ../incident_management/profiles.yml)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Required environment variables:"
            echo "  DBT_SNOWFLAKE_ACCOUNT     - Snowflake account identifier"
            echo "  DBT_PROJECT_DATABASE      - Database name for the project"
            echo "  DBT_PROJECT_ADMIN_ROLE    - Administrative role for the project"
            echo "  DBT_PROJECT_SCHEMA        - Schema name for the project"
            echo "  DBT_SNOWFLAKE_USER        - Snowflake username"
            echo "  DBT_SNOWFLAKE_WAREHOUSE   - Snowflake warehouse name"
            echo "  DBT_TARGET                - DBT target environment (e.g., dev, prod)"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Uses defaults"
            echo "  $0 -e prod.env                       # Uses prod.env file"
            echo "  $0 -t custom.template -o custom.yml  # Custom template and output"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    echo "Please create a .env file with the required environment variables."
    echo "Use '$0 --help' to see the list of required variables."
    exit 1
fi

echo "Using environment file: $ENV_FILE"
source "$ENV_FILE"

# List of required environment variables
required_vars=(
    "DBT_SNOWFLAKE_ACCOUNT"
    "DBT_PROJECT_DATABASE"
    "DBT_PROJECT_ADMIN_ROLE"
    "MODEL_SCHEMA"
    "DBT_SNOWFLAKE_USER"
    "DBT_SNOWFLAKE_WAREHOUSE"
    "DBT_TARGET"
)

# Check if all required environment variables are set
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: The following required environment variables are not set:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please set these variables in your $ENV_FILE file."
    echo "Use '$0 --help' for more information."
    exit 1
fi

# Function to generate profiles.yml from template
generate_profiles_yml() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "Error: Template file '$TEMPLATE_FILE' not found"
        exit 1
    fi
    
    echo "Generating $OUTPUT_FILE from $TEMPLATE_FILE..."
    
    # Create output directory if it doesn't exist
    OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        echo "Created output directory: $OUTPUT_DIR"
    fi
    
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
            
            line="${line//\$\{$var_name\}/$var_value}"
        done
        echo "$line"
    done < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
    
    echo "Successfully generated $OUTPUT_FILE"
    
    # Display generated configuration for verification
    echo ""
    echo "Generated profiles.yml contents:"
    echo "================================"
    cat "$OUTPUT_FILE"
    
    return 0
}

# Verify template file exists before processing
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found"
    echo "Please ensure the profiles.yml.template file exists in the correct location."
    exit 1
fi

# Generate profiles.yml configuration file from template
generate_profiles_yml

echo ""
echo "Profile generation completed successfully!"
echo "You can now use the generated profiles.yml file with dbt commands."
