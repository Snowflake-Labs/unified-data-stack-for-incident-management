#!/bin/bash
# setup_env.sh - DBT Environment Variables Setup Script
# 
# Usage: source setup_env.sh
# This script sets up the environment variables needed for dbt to work with the updated profiles.yml

echo "Setting up DBT environment variables..."

# Required environment variables - UPDATE THESE WITH YOUR ACTUAL VALUES
export DBT_SNOWFLAKE_ACCOUNT=uib27272
export DBT_SNOWFLAKE_USER_DEV=genp_service_usr
export DBT_SNOWFLAKE_PRIVATE_KEY_PATH=/Users/clakkad/.ssh/rsa_key_dbt_os_prod_user.p8
export DBT_SNOWFLAKE_DATABASE_DEV=incident_management
export DBT_SNOWFLAKE_ROLE_DEV=dbt_projects_engineer
export DBT_SNOWFLAKE_SCHEMA_DEV=landing_zone
export DBT_SNOWFLAKE_WAREHOUSE_DEV=incident_management_dbt_wh

# DBT configuration
export DBT_TARGET=dev
export DBT_THREADS=1

echo "✅ Environment variables set:"
echo "   DBT_SNOWFLAKE_ACCOUNT: $DBT_SNOWFLAKE_ACCOUNT"
echo "   DBT_SNOWFLAKE_USER: $DBT_SNOWFLAKE_USER"
echo "   DBT_SNOWFLAKE_PRIVATE_KEY_PATH: $DBT_SNOWFLAKE_PRIVATE_KEY_PATH"
echo "   DBT_TARGET: $DBT_TARGET"
echo "   DBT_THREADS: $DBT_THREADS"
echo ""
echo "🚀 You can now run dbt commands:"
echo "   dbt debug    # Test connection"
echo "   dbt compile  # Compile models"
echo "   dbt run      # Run models"
echo ""
echo "💡 To switch to production:"
echo "   export DBT_TARGET=prod"
