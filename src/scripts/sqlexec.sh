#!/usr/bin/env bash

# Default environment file
ENV_FILE=".env"
# Default flag for running after slack connector
RUN_AFTER_SLACK=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -a|--after-slack)
            RUN_AFTER_SLACK=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --env FILE        Environment file to use (default: .env)"
            echo "  -a, --after-slack     Run the after slack connector SQL script"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Uses default .env file, runs before_slack_connector.sql only"
            echo "  $0 -e prod.env           # Uses prod.env file, runs before_slack_connector.sql only"
            echo "  $0 --env dev.env         # Uses dev.env file, runs before_slack_connector.sql only"
            echo "  $0 -a                    # Uses default .env file, runs both before and after slack connector"
            echo "  $0 -e prod.env -a        # Uses prod.env file, runs both before and after slack connector"
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


snow sql \
--connection uib27272 \
-f "../sql/roles.sql" 

# Execute database objects SQL (uncommented and updated)
snow sql \
--connection uib27272 \
-f "../sql/before_slack_connector.sql"

# Conditionally execute after slack connector SQL if flag is set
if [ "$RUN_AFTER_SLACK" = true ]; then
    echo "Running after slack connector SQL..."
    snow sql \
    --connection uib27272 \
    -f "../sql/after_slack_connector.sql"
else
    echo "Skipping after slack connector SQL (use -a or --after-slack to enable)"
fi