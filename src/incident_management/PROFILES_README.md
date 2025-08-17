# DBT Profiles Configuration with Environment Variables

## Overview

The `profiles.yml` file has been updated to use environment variables for better security and flexibility. This approach allows you to:

- Keep sensitive credentials out of version control
- Easily switch between different environments
- Configure settings without modifying the profiles.yml file

## Required Environment Variables

The following environment variables **must** be set before running dbt:

| Variable | Description | Example |
|----------|-------------|---------|
| `DBT_SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier | `abc12345` |
| `DBT_SNOWFLAKE_USER` | Snowflake username | `your_service_usr` |
| `DBT_SNOWFLAKE_PRIVATE_KEY_PATH` | Path to your private key file | `/Users/path/to/private/key.p8` |

## Optional Environment Variables (with defaults)

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `DBT_SNOWFLAKE_DATABASE` | `incident_management` | Database name for dev |
| `DBT_SNOWFLAKE_ROLE` | `dbt_projects_engineer` | Role for dev environment |
| `DBT_SNOWFLAKE_SCHEMA` | `landing_zone` | Schema for dev environment |
| `DBT_SNOWFLAKE_WAREHOUSE` | `incident_management_dbt_wh` | Warehouse for dev |
| `DBT_SNOWFLAKE_DATABASE_PROD` | `incident_management_prod` | Database name for prod |
| `DBT_SNOWFLAKE_ROLE_PROD` | `dbt_projects_admin` | Role for prod environment |
| `DBT_SNOWFLAKE_SCHEMA_PROD` | `production` | Schema for prod environment |
| `DBT_SNOWFLAKE_WAREHOUSE_PROD` | `incident_management_prod_wh` | Warehouse for prod |
| `DBT_TARGET` | `dev` | Default target environment |
| `DBT_THREADS` | `1` (dev), `4` (prod) | Number of threads |

## Setup Instructions

### Export Variables in Terminal

```bash
# Required variables
export DBT_SNOWFLAKE_ACCOUNT=abc12345
export DBT_SNOWFLAKE_USER=your_service_usr
export DBT_SNOWFLAKE_PRIVATE_KEY_PATH=/Users/path/to/private/key.p8

# Optional overrides (only if you want to change defaults)
export DBT_SNOWFLAKE_DATABASE=my_custom_database
export DBT_TARGET=prod
export DBT_THREADS=2

# Test the configuration
dbt debug
```


## Environment-Specific Configurations

### Development Environment
- Uses the `dev` target by default
- Lower thread count for local development
- Uses development-specific database and schema

### Production Environment
- Use `export DBT_TARGET=prod` to switch to production
- Higher thread count for better performance
- Uses production-specific database, schema, and role

## Validation

After setting your environment variables, validate the configuration:

```bash
# Check if variables are set
echo $DBT_SNOWFLAKE_ACCOUNT
echo $DBT_SNOWFLAKE_USER

# Test dbt connection
dbt debug

# Run a simple command
dbt compile
```

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```
   Error: Required environment variable 'DBT_SNOWFLAKE_ACCOUNT' not found
   ```
   Solution: Ensure all required variables are exported

2. **Connection Failures**
   - Verify your private key path is correct
   - Check that your Snowflake account, user, and role have proper permissions

3. **Incorrect Target**
   ```bash
   # Check current target
   dbt debug | grep "target:"
   
   # Change target
   export DBT_TARGET=prod
   ```

## Security Best Practices

1. **Never commit credentials to version control**
2. **Use environment-specific scripts for different environments**
3. **Regularly rotate private keys and update paths**
4. **Limit database permissions to necessary operations only**
