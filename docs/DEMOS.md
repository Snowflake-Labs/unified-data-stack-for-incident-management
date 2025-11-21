# Demo Vignettes & Usage Examples

This document provides practical examples and demonstrations of the Incident Management platform's key capabilities.

## Table of Contents
- [Overview](#overview)
- [OpenFlow-Based Slack Ingestion](#openflow-based-slack-ingestion)
- [dbt Projects on Snowflake](#dbt-projects-on-snowflake)
- [AI/SQL Integration within dbt Models](#aisql-integration-within-dbt-models)
- [Streamlit Dashboard](#streamlit-dashboard)
- [End-to-End Workflow Example](#end-to-end-workflow-example)

## Overview

This project demonstrates several key modern data platform capabilities through realistic incident management scenarios. Each vignette showcases a specific capability or integration pattern.

## OpenFlow-Based Slack Ingestion

### Scenario
Real-time incident reporting through Slack with automatic data capture and processing.

### Key Features Demonstrated
- Real-time data ingestion from external systems
- Unstructured data handling (text and images)
- Event-driven architecture
- Cloud-native integration patterns

### Demo Flow

1. **Report an Incident in Slack**
   
   Post a message in your configured Slack channel:
   ```
   Payment gateway is returning 500 errors
   ```

2. **Attach Supporting Evidence**
   
   Include a screenshot of the error page (use the sample images provided in `data/images/`):
   - `payment_gateway_outage.jpeg`
   - `invalid_credentials.jpeg`

3. **Verify Ingestion**
   
   Check that the message appears in Snowflake:
   ```sql
   SELECT * 
   FROM SLACK_MESSAGES 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

4. **Process the Data**
   
   If Tasks are not set up, manually run the dbt Project:
   ```bash
   make run-dbt CONN=<your-connection-name>
   ```

5. **View the Result**
   
   Watch as the system creates a structured incident record with AI classification in the Streamlit dashboard.

### What This Demonstrates
- Seamless integration between operational tools and data platforms
- Real-time data availability for analytics
- Support for multi-modal data (text + images)

## dbt Projects on Snowflake

### Scenario 1: Remote Deployment and Execution

Working with dbt Projects directly in Snowflake without local dbt installation.

**Key Capabilities:**
- Deploy dbt projects using Snowflake CLI
- Execute dbt commands remotely
- Leverage Snowflake's compute for transformations

**Example Commands:**

```bash
# Deploy dbt project to Snowflake
make deploy-dbt CONN=<your-connection-name>

# Execute dbt run
make run-dbt CONN=<your-connection-name>

# Execute with model selection
snow dbt run --select gold_zone.incidents
```

### Scenario 2: Using Variables in dbt Projects

The project demonstrates variable usage in [`dbt_project.yml`](../src/incident_management/dbt_project.yml).

**Example:**
```yaml
vars:
  incident_categories:
    - 'payment gateway error'
    - 'login error'
    - 'database connectivity'
    - 'api timeout'
    - 'other'
```

These variables are referenced in models:
```sql
-- In incidents.sql
ai_classify(text, {{ var('incident_categories') }})
```

### Scenario 3: Scalable Data Transformation Pipeline

**Features:**
- Raw Slack data transformed into analytics-ready models
- Incremental processing for performance
- Data quality testing and documentation
- Complete data lineage tracking

**Key Models:**

1. **Bronze Zone: Qualification Layer**
   
   [`v_qualify_slack_messages`](../src/incident_management/models/bronze_zone/v_qualify_slack_messages.sql)
   
   - Filters relevant incident messages
   - Removes duplicates using window functions
   - Prepares clean data for transformation

2. **Gold Zone: Incident Processing**
   
   [`incidents`](../src/incident_management/models/gold_zone/incidents.sql)
   
   - AI-enhanced incident classification
   - Multi-modal analysis (text + images)
   - Automatic priority assignment

3. **Gold Zone: Business Views**
   
   [`active_incidents`](../src/incident_management/models/gold_zone/active_incidents.sql)
   
   - Real-time operational view
   - Enriched with user information
   - Calculated fields (age, SLA status)

### What This Demonstrates
- Modern data engineering best practices
- Scalable transformation patterns
- Incremental processing strategies
- Data quality and testing frameworks

## AI/SQL Integration within dbt Models

### Scenario
Intelligent incident classification and processing using embedded AI functions.

### Unstructured Text Processing

#### Automatic Categorization

Classify incidents using natural language:

```sql
-- From incidents.sql
ai_classify(
  sri.text, 
  ['payment gateway error', 'login error', 'other']
):labels[0] as category
```

**Example Input:**
```
"Users are reporting 500 errors when trying to complete checkout"
```

**AI Output:**
```
category: "payment gateway error"
```

#### Smart Incident Matching

Use AI to find related incidents:

```sql
-- From incident_comment_history.sql
ai_filter(
  prompt(
    'The text category {0} is logically relatable to this record''s category {1}', 
    text_category, 
    roi.category
  )
)
```

**What This Does:**
- Matches new messages to existing incidents
- Uses semantic understanding, not keyword matching
- Automatically threads related comments

### Image Processing

#### Multi-Modal Classification

Analyze both text and images for better classification:

```sql
case 
  when sri.attachment_file is not null then 
    ai_classify(
      sri.attachment_file, 
      ['payment gateway error', 'login error', 'other']
    ):labels[0]
  else 
    ai_classify(
      sri.text, 
      ['payment gateway error', 'login error', 'other']
    ):labels[0]
end as category
```

**Example Scenario:**
1. User posts vague message: "Something is broken"
2. Attaches screenshot of payment error
3. AI analyzes image and correctly classifies as "payment gateway error"

### Priority Assignment

Automatically assign priority based on category:

```sql
case 
  when category in ('payment gateway error', 'database connectivity') 
    then 'Critical'
  when category = 'login error' 
    then 'High'
  else 'Medium'
end as priority
```

### What This Demonstrates
- AI-native data processing without external infrastructure
- Multi-modal AI analysis (text and images)
- Intelligent data enrichment
- No model training or maintenance required

> **See complete implementation:** [`incidents.sql`](../src/incident_management/models/gold_zone/incidents.sql)

## Streamlit Dashboard

### Scenario
Real-time operational dashboard for incident monitoring and management.

### Key Features

#### 1. Real-Time Metrics
- Critical incident count
- High-priority incidents
- Active incidents
- Recently closed incidents
- Priority-based color coding

#### 2. Active Incidents Table
- Live view of open incidents
- Sortable and filterable
- Priority indicators
- Direct links to attachments

#### 3. Attachment Viewing
- In-app image viewing
- No need to download files
- Contextual evidence display

#### 4. Trend Analysis
- Weekly incident volumes
- Category distribution
- Resolution time trends
- Historical comparisons

### Demo Flow

1. **Open the Dashboard**
   
   Navigate to your Streamlit app in Snowsight

2. **View Metrics**
   
   Top section shows key metrics with color coding

3. **Explore Active Incidents**
   
   Scroll through the active incidents table

4. **View an Attachment**
   
   Click on an incident with an attachment icon to view the image

5. **Analyze Trends**
   
   Review the trend charts to identify patterns

### What This Demonstrates
- Real-time data visualization
- Interactive analytics
- Modern user experience
- Operational monitoring capabilities

## End-to-End Workflow Example

This example demonstrates the complete incident lifecycle from report to resolution.

### Complete Incident Journey

#### 1. Report (Slack)

**User Posts:**
```
Our login page is showing 'Invalid credentials' for valid users
```

**Attachment:** Screenshot of login error (`invalid_credentials.jpeg`)

#### 2. Ingest (OpenFlow)

- OpenFlow captures message within seconds
- Stores text in `SLACK_MESSAGES` table
- Saves image file and metadata
- Triggers downstream processing

#### 3. Process (dbt)

**Qualification:**
```sql
-- v_qualify_slack_messages.sql
-- Identifies this as an incident-related message
-- Removes any duplicate posts
```

**AI Classification:**
```sql
-- incidents.sql
-- Text analysis: "Invalid credentials" → login error
-- Image analysis: Confirms authentication issue
-- Priority assignment: HIGH
-- Generates incident ID: INC-2025-0042
```

**Result:**
```
incident_id: INC-2025-0042
title: "Invalid credentials for valid users"
category: "login error"
priority: "High"
status: "Open"
reporter: USLACK123
```

#### 4. Monitor (Streamlit)

- Dashboard updates with new critical incident
- Alert metrics increment
- Incident appears in active incidents table
- Attachment is viewable in-app

#### 5. Resolve (Team Action)

Team investigates and resolves the issue:
- Updates status to "In Progress" 
- Adds comments via Slack thread
- Resolves issue
- Updates status to "Closed"

#### 6. Analyze (System)

System automatically tracks:
- Time to resolution: 2 hours 15 minutes
- Category trending: Login errors increasing
- Resolution quality scoring
- Updates weekly trend reports

### What This Demonstrates

- **Complete modern data stack** handling real-world operational scenarios
- **AI enhancement** at every step
- **Real-time visibility** into operations
- **Automated workflows** reducing manual effort
- **Data-driven insights** for continuous improvement

## Sample Test Scenarios

### Test Scenario 1: Payment Gateway Outage

1. **Message:** "Payment processing is completely down, customers can't check out"
2. **Attachment:** `payment_gateway_outage.jpeg`
3. **Expected Result:**
   - Category: "payment gateway error"
   - Priority: "Critical"
   - Auto-assigned to on-call engineer

### Test Scenario 2: Minor UI Issue

1. **Message:** "The logo is slightly misaligned on mobile devices"
2. **No Attachment**
3. **Expected Result:**
   - Category: "other"
   - Priority: "Low"
   - Added to backlog

### Test Scenario 3: Database Connectivity

1. **Message:** "Getting connection timeout errors to production database"
2. **No Attachment**
3. **Expected Result:**
   - Category: "database connectivity"
   - Priority: "Critical"
   - Immediate escalation

## Running Your Own Tests

1. **Post messages in your Slack channel** with various incident types
2. **Run the dbt project** to process the messages
3. **Check the dashboard** to see how incidents were classified
4. **Verify AI classifications** match expected categories
5. **Test attachment viewing** by uploading screenshots

## Next Steps

- Set up your own Slack channel following the [Setup Guide](SETUP.md)
- Review the [Architecture Documentation](ARCHITECTURE.md) to understand the data flow
- Explore the actual SQL in the model files to see implementation details
- Experiment with different incident scenarios

