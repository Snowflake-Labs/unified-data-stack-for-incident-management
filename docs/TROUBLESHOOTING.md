# Troubleshooting Guide

This guide helps you resolve common issues when setting up and using the Incident Management platform.

## Table of Contents
- [Prerequisites and Setup](#prerequisites-and-setup)
- [Connection Issues](#connection-issues)
- [Slack Connector Issues](#slack-connector-issues)
- [dbt Project Issues](#dbt-project-issues)
- [Streamlit Dashboard Issues](#streamlit-dashboard-issues)
- [Data Processing Issues](#data-processing-issues)
- [Performance Issues](#performance-issues)

## Prerequisites and Setup

### Verify Prerequisites

Run the prerequisites check:

```bash
make check-prereqs
```

### Common Setup Issues

#### Issue: Snowflake CLI Not Found

**Symptoms:**
```
-bash: snow: command not found
```

**Solution:**
1. Install Snowflake CLI following the [official guide](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation)
2. Verify installation:
   ```bash
   snow --version
   ```

#### Issue: Missing Environment Variables

**Symptoms:**
```
Error: Required environment variable not set
```

**Solution:**
1. Verify `.env` file exists in project root
2. Check that all required variables are set:
   ```bash
   cat .env | grep -v '^#' | grep -v '^$'
   ```
3. Source the environment file:
   ```bash
   source .env
   ```

#### Issue: Invalid Connection Configuration

**Symptoms:**
```
Error: Connection '<name>' not found
```

**Solution:**
1. Check your `~/.snowflake/config.toml` file exists
2. Verify connection configuration:
   ```bash
   cat ~/.snowflake/config.toml
   ```
3. Ensure connection name matches what you're using in commands

## Connection Issues

### Cannot Connect to Snowflake

**Symptoms:**
- Connection timeout errors
- Authentication failures
- "Account not found" errors

**Diagnostics:**

1. **Verify Account Name:**
   ```bash
   # Should be in format: <account>.<region>
   # Example: xy12345.us-east-1
   ```

2. **Test Connection:**
   ```bash
   snow connection test --connection <your-connection-name>
   ```

3. **Check Network:**
   ```bash
   ping <your-account>.snowflakecomputing.com
   ```

**Solutions:**

- **Issue:** Wrong account identifier
  - **Fix:** Update `~/.snowflake/config.toml` with correct account locator

- **Issue:** Network/Firewall blocking
  - **Fix:** Contact your network administrator to allow Snowflake connections

- **Issue:** Expired credentials
  - **Fix:** Re-authenticate or regenerate tokens

### ACCOUNTADMIN Privileges Required

**Symptoms:**
```
Insufficient privileges to operate on account
```

**Solution:**
1. Ask your Snowflake administrator for ACCOUNTADMIN role
2. Or request they run the setup scripts on your behalf
3. Verify your role:
   ```sql
   SELECT CURRENT_ROLE();
   ```

## Slack Connector Issues

### Slack Messages Not Appearing in Snowflake

**Symptoms:**
- Messages posted in Slack don't appear in `SLACK_MESSAGES` table
- Table exists but is empty

**Diagnostics:**

1. **Check Connector Status:**
   - Navigate to OpenFlow runtime in Snowsight
   - Verify connector shows as "Running"

2. **Verify Table Exists:**
   ```sql
   SHOW TABLES LIKE 'SLACK_MESSAGES' IN SCHEMA bronze_zone;
   ```

3. **Check for Errors:**
   - Review OpenFlow runtime logs
   - Look for connection errors or permission issues

**Solutions:**

- **Issue:** Slack app not installed in channel
  - **Fix:** Add your Slack app to the channel:
    ```
    /invite @YourIncidentBot
    ```

- **Issue:** Wrong channel configured
  - **Fix:** Verify channel ID in OpenFlow connector configuration

- **Issue:** Insufficient Slack permissions
  - **Fix:** Ensure app has required scopes:
    - `channels:history`
    - `channels:read`
    - `files:read`
    - `users:read`

- **Issue:** External access not configured
  - **Fix:** Update External Access Integration:
    ```sql
    -- Verify slack.com is allowed
    SHOW EXTERNAL ACCESS INTEGRATIONS;
    ```

### Slack Attachments Not Processing

**Symptoms:**
- Text messages work but images don't appear
- `attachment_file` column is NULL

**Solutions:**

1. **Check file permissions:**
   ```sql
   SELECT file_url, attachment_file, error 
   FROM SLACK_MESSAGES 
   WHERE file_url IS NOT NULL;
   ```

2. **Verify Slack app has `files:read` scope**

3. **Check External Access Integration includes Slack file domains:**
   - `files.slack.com`
   - `slack-files.com`

### Duplicate Messages

**Symptoms:**
- Same message appears multiple times in `SLACK_MESSAGES`

**Solution:**

This is handled by the `v_qualify_slack_messages` model using window functions. Ensure you're querying the view, not the raw table:

```sql
-- Use this (deduplicated)
SELECT * FROM bronze_zone.v_qualify_slack_messages;

-- Not this (may have duplicates)
SELECT * FROM bronze_zone.slack_messages;
```

## dbt Project Issues

### dbt Deployment Fails

**Symptoms:**
```
Error deploying dbt project
```

**Diagnostics:**

1. **Check dbt project structure:**
   ```bash
   cd src/incident_management
   ls -la dbt_project.yml
   ```

2. **Verify profiles.yml:**
   ```bash
   cat src/incident_management/profiles.yml
   ```

3. **Test Snowflake connection:**
   ```bash
   snow connection test
   ```

**Solutions:**

- **Issue:** Missing or invalid `dbt_project.yml`
  - **Fix:** Ensure file exists and is valid YAML
  - **Fix:** Verify project name matches configuration

- **Issue:** Wrong database/schema names
  - **Fix:** Update environment variables to match your setup
  - **Fix:** Update `profiles.yml` accordingly

### dbt Run Fails

**Symptoms:**
```
Compilation error
SQL execution error
```

**Diagnostics:**

1. **Check dbt logs:**
   ```bash
   cat src/incident_management/logs/dbt.log
   ```

2. **Run with debug flag:**
   ```bash
   snow dbt run --debug
   ```

3. **Validate individual model:**
   ```bash
   snow dbt run --select incidents --debug
   ```

**Solutions:**

- **Issue:** Source table doesn't exist
  - **Fix:** Verify Slack connector created required tables
  - **Fix:** Run setup scripts in correct order

- **Issue:** Missing AI functions
  - **Fix:** Ensure you're using Snowflake Enterprise or higher
  - **Fix:** Verify Cortex AI is enabled in your region

- **Issue:** Compilation error in SQL
  - **Fix:** Check model syntax
  - **Fix:** Verify Jinja2 template variables

### Authentication Issues with dbt

**Symptoms:**
```
Authentication failed for user
```

**Solutions:**

1. **For password authentication:**
   ```bash
   # Update .env file
   DBT_SNOWFLAKE_PASSWORD=<your-PAT-token>
   ```

2. **For key-pair authentication:**
   ```bash
   # Verify private key exists
   ls -la <path-to-private-key>
   
   # Verify public key is set on user
   SHOW USERS LIKE '<your-user>';
   ```

3. **Regenerate credentials if needed**

## Streamlit Dashboard Issues

### Cannot Access Dashboard

**Symptoms:**
- Dashboard URL returns 404
- "Streamlit app not found" error

**Solutions:**

1. **Verify app was deployed:**
   ```sql
   SHOW STREAMLIT IN ACCOUNT;
   ```

2. **Check app status:**
   ```sql
   DESCRIBE STREAMLIT incident_management_dashboard;
   ```

3. **Redeploy if necessary:**
   ```bash
   make deploy-streamlit CONN=<your-connection-name>
   ```

### Dashboard Shows No Data

**Symptoms:**
- Dashboard loads but tables are empty
- Metrics show zero

**Solutions:**

1. **Check data exists in tables:**
   ```sql
   SELECT COUNT(*) FROM gold_zone.active_incidents;
   SELECT COUNT(*) FROM gold_zone.incidents;
   ```

2. **Verify dbt models ran successfully:**
   ```sql
   SELECT * FROM gold_zone.incidents LIMIT 5;
   ```

3. **Re-run dbt if needed:**
   ```bash
   make run-dbt CONN=<your-connection-name>
   ```

### Attachment Images Not Displaying

**Symptoms:**
- Attachment icon appears but image won't load
- Error when clicking on attachment

**Solutions:**

1. **Verify file exists in Snowflake:**
   ```sql
   SELECT incident_id, attachment_file 
   FROM gold_zone.incident_attachments 
   WHERE attachment_file IS NOT NULL;
   ```

2. **Check file permissions:**
   - Ensure Streamlit app role has read access to stage
   - Verify External Access Integration if loading from URL

## Data Processing Issues

### AI Classification Not Working

**Symptoms:**
- `category` column is NULL or always "other"
- AI functions return errors

**Diagnostics:**

1. **Check Cortex AI availability:**
   ```sql
   -- Try a simple classification
   SELECT ai_classify('This is a test', ['category1', 'category2']);
   ```

2. **Verify function syntax:**
   ```sql
   -- Check incidents model
   SELECT * FROM gold_zone.incidents LIMIT 1;
   ```

**Solutions:**

- **Issue:** Cortex AI not available in region
  - **Fix:** Check [Cortex AI availability](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions#availability)
  - **Fix:** Use a supported region

- **Issue:** Insufficient privileges
  - **Fix:** Grant required permissions:
    ```sql
    GRANT USAGE ON CORTEX TO ROLE dbt_projects_engineer;
    ```

- **Issue:** Invalid categories list
  - **Fix:** Verify `incident_categories` variable in `dbt_project.yml`

### Incident IDs Not Generating

**Symptoms:**
- `incident_id` is NULL
- Duplicate incident IDs

**Solution:**

Check the ID generation logic in `incidents.sql`:

```sql
SELECT 
  'INC-' || YEAR(created_at) || '-' || 
  LPAD(ROW_NUMBER() OVER (ORDER BY created_at), 4, '0') as incident_id
FROM ...
```

Ensure `created_at` timestamp exists and is valid.

### Incremental Models Not Processing New Data

**Symptoms:**
- New Slack messages don't create new incidents
- Data appears stale

**Solutions:**

1. **Check incremental strategy:**
   ```sql
   -- Should have is_incremental() logic
   ```

2. **Force full refresh:**
   ```bash
   snow dbt run --full-refresh
   ```

3. **Verify source freshness:**
   ```bash
   snow dbt source freshness
   ```

## Performance Issues

### dbt Runs Taking Too Long

**Symptoms:**
- Transformations take minutes instead of seconds
- Warehouse running at capacity

**Solutions:**

1. **Check warehouse size:**
   ```sql
   SHOW WAREHOUSES LIKE 'v1_demo_wh';
   ```

2. **Increase warehouse size temporarily:**
   ```sql
   ALTER WAREHOUSE v1_demo_wh SET WAREHOUSE_SIZE = 'MEDIUM';
   ```

3. **Review query plans:**
   ```sql
   -- Check for full table scans
   EXPLAIN SELECT * FROM gold_zone.incidents;
   ```

4. **Optimize incremental models:**
   - Ensure proper partitioning
   - Use appropriate incremental strategy
   - Add clustering keys if needed

### Dashboard Loading Slowly

**Symptoms:**
- Streamlit app takes long to load
- Queries timing out

**Solutions:**

1. **Create materialized views for dashboard queries:**
   ```sql
   -- Instead of querying heavy tables repeatedly
   CREATE VIEW dashboard_summary AS
   SELECT ...
   ```

2. **Add filters to limit data:**
   - Filter to recent incidents only
   - Limit attachment loading

3. **Review query performance:**
   ```sql
   SELECT * 
   FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   WHERE query_text LIKE '%active_incidents%'
   ORDER BY start_time DESC
   LIMIT 10;
   ```

## Getting Additional Help

### Enable Debug Logging

For more detailed error messages:

```bash
# For dbt
snow dbt run --debug --log-level debug

# For Snowflake CLI
snow --debug <command>
```

### Check System Logs

1. **dbt logs:**
   ```bash
   cat src/incident_management/logs/dbt.log
   ```

2. **Snowflake query history:**
   ```sql
   SELECT *
   FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   WHERE start_time > DATEADD(hour, -1, CURRENT_TIMESTAMP())
   ORDER BY start_time DESC;
   ```

3. **OpenFlow runtime logs:**
   - Navigate to OpenFlow runtime in Snowsight
   - Check container logs

### Contact Support

If issues persist after trying these solutions:

1. **Gather diagnostic information:**
   - Error messages (full text)
   - Steps to reproduce
   - Environment details (Snowflake region, account type)
   - Relevant log excerpts

2. **Create GitHub issue:**
   - Include diagnostic information
   - Tag with appropriate label
   - Describe expected vs. actual behavior

3. **Email support:**
   - Send details to: chinmayee.lakkad@snowflake.com

## Useful Commands Reference

```bash
# Verify prerequisites
make check-prereqs

# Test Snowflake connection
snow connection test --connection <name>

# Check dbt project structure
snow dbt debug

# Run specific model
snow dbt run --select <model_name>

# View dbt documentation
snow dbt docs generate
snow dbt docs serve

# Full refresh all models
snow dbt run --full-refresh

# Run tests
snow dbt test
```

## Additional Resources

- [Snowflake Documentation](https://docs.snowflake.com/)
- [dbt Documentation](https://docs.getdbt.com/)
- [OpenFlow Documentation](https://docs.snowflake.com/en/user-guide/data-integration/openflow)
- [Project GitHub Issues](https://github.com/Snowflake-Labs/unified-data-stack-for-incident-management/issues)

