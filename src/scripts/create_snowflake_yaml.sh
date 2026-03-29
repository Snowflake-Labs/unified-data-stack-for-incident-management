#!/usr/bin/env bash

# This script generates snowflake.yml configuration file from template using environment variables
#
# Usage examples:
# Basic usage with default .env:
#   ./create_snowflake_yaml.sh
#
# Use custom environment file:
#   ./create_snowflake_yaml.sh -e prod.env
#
# Use custom template and output files:
#   ./create_snowflake_yaml.sh -t custom.template -o custom.yml
#

# Default values
ENV_FILE=".env"
TEMPLATE_FILE="snowflake.yml.template"
OUTPUT_FILE="../sql/snowflake.yml"

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
            echo "  -t, --template FILE   Template file to use (default: snowflake.yml.template)"
            echo "  -o, --output FILE     Output file to generate (default: snowflake.yml)"
            echo "  -h, --help            Show this help message"
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
    exit 1
fi

echo "Using environment file: $ENV_FILE"
source "$ENV_FILE"

# Function to generate snowflake.yml from template
generate_snowflake_yml() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "Error: Template file '$TEMPLATE_FILE' not found"
        exit 1
    fi
    
    echo "Generating $OUTPUT_FILE from $TEMPLATE_FILE..."
    
    # Read template and substitute environment variables, skipping unset ones
    while IFS= read -r line || [[ -n "$line" ]]; do
        local skip=false

        # Check all referenced vars; skip the line if any are unset
        local check_line="$line"
        while [[ $check_line =~ \$\{([^}]+)\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            if [ -z "${!var_name+x}" ] || [ -z "${!var_name}" ]; then
                skip=true
                break
            fi
            check_line="${check_line#*\}}"
        done

        if $skip; then
            continue
        fi

        # Substitute all ${VAR_NAME} patterns with their values
        while [[ $line =~ \$\{([^}]+)\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${!var_name}"
            line="${line//\$\{$var_name\}/$var_value}"
        done
        echo "$line"
    done < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
    
    echo "Successfully generated $OUTPUT_FILE"
    return 0
}

# Generate snowflake.yml configuration file from template
generate_snowflake_yml
