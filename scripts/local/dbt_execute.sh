snow dbt execute $DBT_PROJECT_NAME \
        --source $DBT_PROJECT_DIR \
        --profiles-dir $DBT_PROFILES_DIR \
        --connection $SNOW_CLI_CONNECTION \
        --database "$DBT_PROJECT_DATABASE" \
        --schema "$DBT_PROJECT_SCHEMA" \
        --role "$DBT_PROJECT_ADMIN_ROLE" \
        --warehouse "$DBT_SNOWFLAKE_WAREHOUSE" \
        --password "$DBT_SNOWFLAKE_PASSWORD"