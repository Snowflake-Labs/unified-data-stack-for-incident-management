create or replace semantic view incident_management.semantic_views.alpha
  

TABLES(
  full_doc_extracts as incident_management.bronze_zone.document_full_extracts
    COMMENT = 'All policy documents'
  , users as incident_management.bronze_zone.users
    COMMENT = 'Materialized users table with enriched data'
  , v_slack_msgs as incident_management.bronze_zone.v_qualify_slack_messages
    COMMENT = 'Qualified Slack messages from known reporters with optional attachment metadata and extracted incident number'
  , incidents as incident_management.gold_zone.incidents
    COMMENT = 'Materialized incidents table with enriched data and calculated fields'
  , active_incidents as incident_management.gold_zone.active_incidents
    COMMENT = 'Active incidents requiring attention with SLA status and priority ordering'
  , closed_incidents as incident_management.gold_zone.closed_incidents
    COMMENT = 'Closed incidents with resolution metrics and performance insights'
  , incident_attachments as incident_management.gold_zone.incident_attachments
    COMMENT = 'Materialized incident attachments table'
  , incident_comment_history as incident_management.gold_zone.incident_comment_history
    COMMENT = 'Simplified incident comment history for tracking communication'
  , weekly_incident_trends as incident_management.gold_zone.weekly_incident_trends
    COMMENT = 'Weekly incident trends for the last 12 weeks'

)

FACTS (
    full_doc_extracts.size AS size
      COMMENT = 'Size of the file in bytes'
      
    , full_doc_extracts.page_num AS page_num
      COMMENT = 'Source page number for the extracted content'
      
    , v_slack_msgs.file_size AS slack_file_size
      COMMENT = 'Attachment file size'

    , active_incidents.age_hours AS active_incident_age_hours
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
    , weekly_incident_trends.closed_incidents AS closed_incidents_count
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
 )

 DIMENSIONS (
    full_doc_extracts.relative_path as relative_path
      COMMENT = 'Path to the file on the stage'
    , full_doc_extracts.last_modified AS last_modified
      COMMENT = 'Timestamp when the file was last updated in the stage'
    , full_doc_extracts.md5 AS md5
      COMMENT = 'MD5 checksum for the file'
    ,full_doc_extracts.etag AS etag
      COMMENT = 'ETag header for the file'
    , full_doc_extracts.file_url AS file_url
      WITH SYNONYMS = ('file url', 'snowflake file url')
      COMMENT = 'Snowflake file URL to the file'
    ,full_doc_extracts.doc_type AS doc_type
      WITH SYNONYMS = ('document type', 'doc type', 'analysis type')
      COMMENT = 'Type of document classification (e.g., ''full'', ''question'', ''slack'')'
    ,full_doc_extracts.extension AS extension
      WITH SYNONYMS = ('extension', 'file extension')
      COMMENT = 'File extension parsed from the path'
    ,full_doc_extracts.chunk AS chunk
      WITH SYNONYMS = ('chunk', 'text')
      COMMENT = 'Markdown/text chunk content extracted from the document pages'
    ,full_doc_extracts.headers AS headers
      WITH SYNONYMS = ('headers', 'detected headers')
      COMMENT = 'Object of detected headers for the chunk (e.g., header_1, header_2)'

    , users.id AS user_id
      COMMENT = 'Unique user identifier'
    , users.email AS user_email
      COMMENT = 'Primary email address'
    ,users.first_name AS user_first_name
      COMMENT = 'First name parsed from email user part'
    ,users.last_name AS user_last_name
      COMMENT = 'Last name parsed from email domain part'
    ,users.role AS user_role
      COMMENT = 'User role'
    ,users.department AS user_department
      COMMENT = 'User department'
    ,users.team AS user_team
      COMMENT = 'User team'
    , users.is_active AS user_is_active
      COMMENT = 'Active flag'
    , users.created_at AS user_created_at
      COMMENT = 'Creation timestamp'
    , users.updated_at AS user_updated_at
      COMMENT = 'Last update timestamp'

    , v_slack_msgs.hasfiles AS slack_hasfiles
      COMMENT = 'Whether the message has attachments'
    , v_slack_msgs.type AS slack_type
      COMMENT = 'Slack message type'
    , v_slack_msgs.subtype AS slack_subtype
      COMMENT = 'Slack message subtype'
    , v_slack_msgs.team AS slack_team
      COMMENT = 'Slack team identifier'
    , v_slack_msgs.channel AS slack_channel
      COMMENT = 'Slack channel identifier'
    , v_slack_msgs.user AS slack_user
      COMMENT = 'Slack user identifier'
    , v_slack_msgs.username AS slack_username
      COMMENT = 'Slack username'
    , v_slack_msgs.reporter_id AS slack_reporter_id
      COMMENT = 'Matched reporter id from users'
    , v_slack_msgs.text AS slack_text
      COMMENT = 'Slack message text'
    , v_slack_msgs.ts AS slack_ts
      COMMENT = 'Slack message timestamp'
    , v_slack_msgs.slack_message_id AS slack_message_id
      COMMENT = 'Unique Slack message id'
    , v_slack_msgs.file_id AS slack_file_id
      COMMENT = 'Attachment file id'
    , v_slack_msgs.file_name AS slack_file_name
      COMMENT = 'Attachment file name'
    , v_slack_msgs.file_mimetype AS slack_file_mimetype
      COMMENT = 'Attachment file mimetype'
    , v_slack_msgs.staged_file_path AS slack_staged_file_path
      COMMENT = 'Path to staged file'
    , v_slack_msgs.attachment_file AS slack_attachment_file
      COMMENT = 'Stage file reference'
    , v_slack_msgs.incident_number AS slack_incident_number
      COMMENT = 'Extracted incident number from image or text'


    , incidents.incident_number AS incident_number
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
  )