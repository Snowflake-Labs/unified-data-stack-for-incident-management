{{ config(materialized='semantic_view') }}

TABLES(
  incidents as {{ ref('incidents') }}
    COMMENT = 'Materialized incidents table with enriched data and calculated fields'

  , active_incidents as {{ ref('active_incidents') }}
    COMMENT = 'Active incidents requiring attention with SLA status and priority ordering'

  , closed_incidents as {{ ref('closed_incidents') }}
    COMMENT = 'Closed incidents with resolution metrics and performance insights'

  , incident_attachments as {{ ref('incident_attachments') }}
    COMMENT = 'Materialized incident attachments table'

  , incident_comment_history as {{ ref('incident_comment_history') }}
    COMMENT = 'Simplified incident comment history for tracking communication'

  , weekly_incident_trends as {{ ref('weekly_incident_trends') }}
    COMMENT = 'Weekly incident trends for the last 12 weeks'

  , quaterly_review_metrics as {{ ref('quaterly_review_metrics') }}
    COMMENT = 'Quarterly review metrics'

)

FACTS (
    active_incidents.age_hours AS age_hours
      COMMENT = 'Age of incident in hours'
    , closed_incidents.total_resolution_hours AS total_resolution_hours
      COMMENT = 'Total time from creation to closure in hours'
    , closed_incidents.closed_year AS closed_year
      COMMENT = 'Year when the incident was closed'
    , closed_incidents.closed_quarter AS closed_quarter
      COMMENT = 'Quarter when the incident was closed'

    , weekly_incident_trends.total_incidents AS total_incidents
      COMMENT = 'Total incidents created in the week'
    , weekly_incident_trends.resolved_incidents AS resolved_incidents
      COMMENT = 'Incidents resolved in the week'
    , weekly_incident_trends.closed_incidents AS closed_incidents
      COMMENT = 'Incidents closed in the week'
    , weekly_incident_trends.open_incidents AS open_incidents
      COMMENT = 'Incidents open in the week'
    , weekly_incident_trends.critical_incidents AS critical_incidents
      COMMENT = 'Incidents with critical priority'
    , weekly_incident_trends.high_incidents AS high_incidents
      COMMENT = 'Incidents with high priority'
    , weekly_incident_trends.high_severity_incidents AS high_severity_incidents
      COMMENT = 'Incidents with critical or high priority'
    , weekly_incident_trends.payment_incidents AS payment_incidents
      COMMENT = 'Payment category incidents'
    , weekly_incident_trends.authentication_incidents AS authentication_incidents
      COMMENT = 'Authentication category incidents'
    , weekly_incident_trends.performance_incidents AS performance_incidents
      COMMENT = 'Performance category incidents'
    , weekly_incident_trends.security_incidents AS security_incidents
      COMMENT = 'Security category incidents'
    , weekly_incident_trends.monitoring_incidents AS monitoring_incidents
      COMMENT = 'Incidents from monitoring source system'
    , weekly_incident_trends.customer_portal_incidents AS customer_portal_incidents
      COMMENT = 'Incidents from customer portal source system'
    , weekly_incident_trends.avg_resolution_time_hours AS avg_resolution_time_hours
      COMMENT = 'Average resolution time in hours'
    , weekly_incident_trends.incidents_with_attachments AS incidents_with_attachments
      COMMENT = 'Incidents that had attachments'
    , weekly_incident_trends.resolution_rate_percentage AS resolution_rate_percentage
      COMMENT = 'Share of resolved/closed incidents as a percentage'

    , quaterly_review_metrics.soh_overall_uptime AS service_operational_health_overall_uptime
      COMMENT = 'Actual recorded overall uptime of all services'
    , quaterly_review_metrics.soh_critical_uptime AS service_operational_health_critical_services_uptime
      COMMENT = 'Actual recorded uptime of critical services'
    , quaterly_review_metrics.soh_sev1_incidents AS service_operational_health_sev_1_incidents
      COMMENT = 'Recorded number of Sev-1 incidents'
    , quaterly_review_metrics.soh_sev2_incidents AS service_operational_health_sev_2_incidents
      COMMENT = 'Recorded number of Sev-2 incidents'
    , quaterly_review_metrics.soh_mtta AS service_operational_health_mtta
      COMMENT = 'Mean time to acknowledge an incident'
    , quaterly_review_metrics.soh_mttr AS service_operational_health_mttr
      COMMENT = 'Mean time to recover from an incident'
    , quaterly_review_metrics.soh_cfr AS service_operational_health_change_failure_rate
      COMMENT = 'Change failure rate'
    , quaterly_review_metrics.soh_slo_breaches AS service_operational_health_slo_breaches
      COMMENT = 'Number of SLO breaches'
    , quaterly_review_metrics.soh_error_budget AS service_operational_health_error_budget_consumed
      COMMENT = 'Error budget consumed'
    , quaterly_review_metrics.soh_downtime AS service_operational_health_service_downtime
      COMMENT = 'Service downtime'
    , quaterly_review_metrics.soh_unplanned_outage_hours AS service_operational_health_unplanned_outage_hours
      COMMENT = 'Unplanned outage hours'
    , quaterly_review_metrics.soh_planned_maintenance_hours AS service_operational_health_planned_maintenance_hours
      COMMENT = 'Planned maintenance hours'
    , quaterly_review_metrics.soh_sev1_outage_minutes AS service_operational_health_sev_1_outage_minutes
      COMMENT = 'Sev-1 outage minutes'
    , quaterly_review_metrics.soh_sev2_outage_minutes AS service_operational_health_sev_2_outage_minutes
      COMMENT = 'Sev-2 outage minutes'
    , quaterly_review_metrics.soh_longest_outage AS service_operational_health_longest_single_outage
      COMMENT = 'Longest single outage'
    , quaterly_review_metrics.soh_mtbft AS service_operational_health_mtbft
      COMMENT = 'Mean time between failures'

    , quaterly_review_metrics.tu_eoq_it_headcount AS team_utilisation_end_of_quarter_it_headcount
      COMMENT = 'End of quarter IT headcount'
    , quaterly_review_metrics.tu_eng_headcount AS team_utilisation_engineering_headcount
      COMMENT = 'Engineering headcount'
    , quaterly_review_metrics.tu_on_call_coverage AS team_utilisation_on_call_coverage
      COMMENT = 'On call coverage'
    , quaterly_review_metrics.tu_project_work_alloc AS team_utilisation_project_work_allocation
      COMMENT = 'Project work allocation'
    , quaterly_review_metrics.tu_bau_ops_alloc AS team_utilisation_bau_operations_allocation
      COMMENT = 'BAU/Operations allocation'
    , quaterly_review_metrics.tu_on_call_hours_per_eng AS team_utilisation_on_call_hours_per_engineer
      COMMENT = 'On call hours per engineer'
    , quaterly_review_metrics.tu_after_hours_incidents AS team_utilisation_after_hours_incidents_handled
      COMMENT = 'After hours incidents handled'
    , quaterly_review_metrics.tu_training_hours_per_fte AS team_utilisation_training_hours_per_fte
      COMMENT = 'Training hours per FTE'
    , quaterly_review_metrics.tu_certifications AS team_utilisation_certifications_earned
      COMMENT = 'Certifications earned'
    , quaterly_review_metrics.tu_attrition AS team_utilisation_attrition
      COMMENT = 'Attrition'

    , quaterly_review_metrics.tls_atlassian AS tool_licensing_spend_atlassian_spend
      COMMENT = 'Spend on Atlassian licenses'
    , quaterly_review_metrics.tls_github AS tool_licensing_spend_github_spend
      COMMENT = 'Spend on GitHub licenses'
    , quaterly_review_metrics.tls_slack AS tool_licensing_spend_slack_spend
      COMMENT = 'Spend on Slack licenses'
    , quaterly_review_metrics.tls_pagerduty AS tool_licensing_spend_pagerduty_spend
      COMMENT = 'Spend on PagerDuty licenses'
    , quaterly_review_metrics.tls_datadog AS tool_licensing_spend_datadog_spend
      COMMENT = 'Spend on Datadog licenses'
    , quaterly_review_metrics.tls_sentry AS tool_licensing_spend_sentry_spend
      COMMENT = 'Spend on Sentry licenses'
    , quaterly_review_metrics.tls_okta AS tool_licensing_spend_okta_spend
      COMMENT = 'Spend on Okta licenses'
    , quaterly_review_metrics.tls_aws AS tool_licensing_spend_aws_spend
      COMMENT = 'Spend on AWS licenses'
    , quaterly_review_metrics.tls_total AS tool_licensing_spend_total_spend
      COMMENT = 'Total spend on licenses'
 )

 DIMENSIONS (
    incidents.incident_number AS incident_number
      COMMENT = 'Incident identifier'
    , incidents.category AS incident_category
      COMMENT = 'Incident category'
    , incidents.title AS incident_title
      COMMENT = 'Incident title'
    , incidents.priority AS incident_priority
      COMMENT = 'Incident priority'
    , incidents.status AS incident_status
      COMMENT = 'Incident status'
    , incidents.assignee_id AS incident_assignee_id
      COMMENT = 'Assignee user id'
    , incidents.reportee_id AS incident_reportee_id
      COMMENT = 'Reportee user id'
    , incidents.created_at AS incident_created_at
      COMMENT = 'Creation timestamp'
    , incidents.closed_at AS incident_closed_at
      COMMENT = 'Close timestamp'
    , incidents.updated_at AS incident_updated_at
      COMMENT = 'Last update timestamp'
    , incidents.source_system AS incident_source_system
      COMMENT = 'Source system for the incident'
    ,incidents.external_source_id AS incident_external_source_id
      COMMENT = 'External source identifier'
    , incidents.has_attachments AS incident_has_attachments
      COMMENT = 'Whether the incident has attachments'
    , incidents.slack_message_id AS incident_slack_message_id
      COMMENT = 'Associated Slack message id'
    , incidents.last_comment AS incident_last_comment
      COMMENT = 'Latest comment content'

    , active_incidents.incident_number AS active_incident_number
      COMMENT = 'Incident identifier'
    , active_incidents.title AS active_incident_title
      COMMENT = 'Incident title'
    , active_incidents.category AS active_incident_category
      COMMENT = 'Incident category'
    , active_incidents.priority AS active_incident_priority
      COMMENT = 'Incident priority'
    , active_incidents.status AS active_incident_status
      COMMENT = 'Incident status'
    , active_incidents.assignee_id AS active_incident_assignee_id
      COMMENT = 'Assignee user id'
    , active_incidents.assignee_name AS active_incident_assignee_name
      COMMENT = 'Assignee full name'
    , active_incidents.reportee_id AS active_incident_reportee_id
      COMMENT = 'Reportee user id'
    , active_incidents.reportee_name AS active_incident_reportee_name
      COMMENT = 'Reportee full name'
    , active_incidents.created_at AS active_incident_created_at
      COMMENT = 'Creation timestamp'
    , active_incidents.updated_at AS active_incident_updated_at
      COMMENT = 'Last update timestamp'
    , active_incidents.source_system AS active_incident_source_system
      COMMENT = 'Source system for the incident'
    , active_incidents.external_source_id AS active_incident_external_source_id
      COMMENT = 'External source identifier'
    , active_incidents.has_attachments AS active_incident_has_attachments
      COMMENT = 'Whether the incident has attachments'

    , closed_incidents.incident_number AS closed_incident_number
      COMMENT = 'Incident identifier'
    , closed_incidents.title AS closed_incident_title
      COMMENT = 'Incident title'
    , closed_incidents.category AS closed_incident_category
      COMMENT = 'Incident category'
    , closed_incidents.priority AS closed_incident_priority
      COMMENT = 'Incident priority'
    , closed_incidents.status AS closed_incident_status
      COMMENT = 'Incident status'
    , closed_incidents.assignee_id AS closed_incident_assignee_id
      COMMENT = 'Assignee user id'
    , closed_incidents.reportee_id AS closed_incident_reportee_id
      COMMENT = 'Reportee user id'
    , closed_incidents.created_at AS closed_incident_created_at
      COMMENT = 'Creation timestamp'
    , closed_incidents.closed_at AS closed_incident_closed_at
      COMMENT = 'Close timestamp'
    , closed_incidents.updated_at AS closed_incident_updated_at
      COMMENT = 'Last update timestamp'
    , closed_incidents.source_system AS closed_incident_source_system
      COMMENT = 'Source system for the incident'
    , closed_incidents.external_source_id AS closed_incident_external_source_id
      COMMENT = 'External source identifier'
    , closed_incidents.has_attachments AS closed_incident_has_attachments
      COMMENT = 'Whether the incident had attachments'
    , closed_incidents.closed_month AS closed_incident_month
      COMMENT = 'Month when incident was closed'

    , incident_attachments.id AS attachment_id
      COMMENT = 'Attachment id'
    , incident_attachments.incident_number AS attachment_incident_number
      COMMENT = 'Incident identifier'
    , incident_attachments.attachment_file AS attachment_file
      COMMENT = 'Stage file reference for the attachment'
    , incident_attachments.uploaded_at AS attachment_uploaded_at
      COMMENT = 'Attachment upload timestamp'

    , incident_comment_history.id AS comment_id
      COMMENT = 'Comment id'
    , incident_comment_history.incident_number AS comment_incident_number
      COMMENT = 'Incident identifier'
    , incident_comment_history.author_id AS comment_author_id
      COMMENT = 'Comment author user id'
    ,  incident_comment_history.content AS comment_content
      COMMENT = 'Comment content'
    , incident_comment_history.created_at AS comment_created_at
      COMMENT = 'Comment creation timestamp'
    , weekly_incident_trends.week AS trend_week
      COMMENT = 'Week bucket (date truncated to week)'

    , quaterly_review_metrics.relative_path AS qrm_relative_path
      COMMENT = 'Path to the file on the stage'
    , quaterly_review_metrics.quarter AS review_quarter
      COMMENT = 'Year and quarter of the review metrics'
  )

 