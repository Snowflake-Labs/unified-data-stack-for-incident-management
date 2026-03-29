{{ config(materialized='semantic_view') }}

TABLES(
  incidents as {{ ref('incidents') }}
    PRIMARY KEY(incident_number)
    COMMENT = 'Materialized incidents table with enriched data and calculated fields'

  , active_incidents as {{ ref('active_incidents') }}
    COMMENT = 'Active incidents requiring attention with SLA status and priority ordering'

  , closed_incidents as {{ ref('closed_incidents') }}
    COMMENT = 'Closed incidents with resolution metrics and performance insights'

  , incident_attachments as {{ ref('incident_attachments') }}
    COMMENT = 'Materialized incident attachments table'

  , incident_comment_history as {{ ref('incident_comment_history') }}
    COMMENT = 'Simplified incident comment history for tracking communication'

  , quaterly_review_metrics as {{ ref('quaterly_review_metrics') }}
    COMMENT = 'Quarterly review metrics'

  , users as {{ ref('users') }}
    COMMENT = 'Materialized users table with enriched data'

)

RELATIONSHIPS (
    active_incidents_to_incidents AS
      active_incidents (incident_number) REFERENCES incidents (incident_number)
    , closed_incidents_to_incidents AS
      closed_incidents (incident_number) REFERENCES incidents (incident_number)
    , incident_attachments_to_incidents AS
      incident_attachments (incident_number) REFERENCES incidents (incident_number)
    , incident_comment_history_to_incidents AS
      incident_comment_history (incident_number) REFERENCES incidents (incident_number)
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

 )

 DIMENSIONS (
    incidents.incident_number AS incident_number
    WITH SYNONYMS = ('incident', 'incident id')
      COMMENT = 'Incident identifier'
   , incidents.category AS category
      WITH SYNONYMS = ('incident category', 'issue category', 'problem category', 'problem type')
      COMMENT = 'Incident category'
   , incidents.title AS title
      WITH SYNONYMS = ('incident title', 'issue title', 'problem title', 'problem description')
      COMMENT = 'Incident title'
   , incidents.priority AS priority
      COMMENT = 'Incident priority'
   , incidents.status AS status
      WITH SYNONYMS = ('incident status', 'issue status', 'problem status', 'state')
      COMMENT = 'Incident status'
   , incidents.assignee_id AS assignee_id
      WITH SYNONYMS = ('assignee', 'assigned to', 'owner', 'resolver')
      COMMENT = 'Assignee user id'
   , incidents.reportee_id AS reportee_id
      WITH SYNONYMS = ('reporter', 'reported by', 'submitter', 'requester')
      COMMENT = 'Reportee user id'
   , incidents.created_at AS created_at
      WITH SYNONYMS = ('created date', 'open date', 'reported at', 'submission time')
      COMMENT = 'Creation timestamp'
   , incidents.closed_at AS closed_at
      WITH SYNONYMS = ('closed date', 'resolved at', 'resolution date', 'end time')
      COMMENT = 'Close timestamp'
   , incidents.updated_at AS updated_at
      WITH SYNONYMS = ('last modified', 'modified date', 'last changed', 'update time')
      COMMENT = 'Last update timestamp'
   , incidents.source_system AS source_system
      WITH SYNONYMS = ('origin', 'source app', 'reporting channel', 'intake system')
      COMMENT = 'Source system for the incident'
   ,incidents.external_source_id AS external_source_id
      WITH SYNONYMS = ('external id', 'channel id', 'source reference', 'external ticket')
      COMMENT = 'External source identifier'
   , incidents.has_attachments AS has_attachments
      WITH SYNONYMS = ('attachments', 'files attached', 'has files', 'includes documents')
      COMMENT = 'Whether the incident has attachments'
   , incidents.slack_message_id AS slack_message_id
      WITH SYNONYMS = ('message id', 'slack msg', 'chat message', 'conversation id')
      COMMENT = 'Associated Slack message id'
   , incidents.last_comment AS last_comment
      WITH SYNONYMS = ('latest note', 'recent comment', 'last update text', 'last message')
      COMMENT = 'Latest comment content'

   , active_incidents.incident_number AS incident_number
      COMMENT = 'Incident identifier'
   , active_incidents.title AS title
      COMMENT = 'Incident title'
   , active_incidents.category AS category
      COMMENT = 'Incident category'
   , active_incidents.priority AS priority
      COMMENT = 'Incident priority'
   , active_incidents.status AS status
      COMMENT = 'Incident status'
   , active_incidents.assignee_id AS assignee_id
      COMMENT = 'Assignee user id'
   , active_incidents.assignee_name AS assignee_name
      COMMENT = 'Assignee full name'
   , active_incidents.reportee_id AS reportee_id
      COMMENT = 'Reportee user id'
   , active_incidents.reportee_name AS reportee_name
      COMMENT = 'Reportee full name'
   , active_incidents.created_at AS created_at
      COMMENT = 'Creation timestamp'
   , active_incidents.updated_at AS updated_at
      COMMENT = 'Last update timestamp'
   , active_incidents.source_system AS source_system
      COMMENT = 'Source system for the incident'
   , active_incidents.external_source_id AS external_source_id
      COMMENT = 'External source identifier'
   , active_incidents.has_attachments AS has_attachments
      COMMENT = 'Whether the incident has attachments'

   , closed_incidents.incident_number AS incident_number
      COMMENT = 'Incident identifier'
   , closed_incidents.title AS title
      COMMENT = 'Incident title'
   , closed_incidents.category AS category
      COMMENT = 'Incident category'
   , closed_incidents.priority AS priority
      COMMENT = 'Incident priority'
   , closed_incidents.status AS status
      COMMENT = 'Incident status'
   , closed_incidents.assignee_id AS assignee_id
      COMMENT = 'Assignee user id'
   , closed_incidents.reportee_id AS reportee_id
      COMMENT = 'Reportee user id'
   , closed_incidents.created_at AS created_at
      COMMENT = 'Creation timestamp'
   , closed_incidents.closed_at AS closed_at
      COMMENT = 'Close timestamp'
   , closed_incidents.updated_at AS updated_at
      COMMENT = 'Last update timestamp'
   , closed_incidents.source_system AS source_system
      COMMENT = 'Source system for the incident'
   , closed_incidents.external_source_id AS external_source_id
      COMMENT = 'External source identifier'
   , closed_incidents.has_attachments AS has_attachments
      COMMENT = 'Whether the incident had attachments'
   , closed_incidents.closed_month AS closed_month
      COMMENT = 'Month when incident was closed'

   , incident_attachments.id AS id
      WITH SYNONYMS = ('attachment id', 'file id')
      COMMENT = 'Attachment id'
   , incident_attachments.incident_number AS incident_number
      WITH SYNONYMS = ('incident', 'incident id')
      COMMENT = 'Incident identifier'
    , incident_attachments.attachment_file AS attachment_file
      WITH SYNONYMS = ('stage file')
      COMMENT = 'Stage file reference for the attachment'
    , incident_attachments.uploaded_at AS uploaded_at
      COMMENT = 'Attachment upload timestamp'

   , incident_comment_history.id AS id
      COMMENT = 'Comment id'
   , incident_comment_history.incident_number AS incident_number
      COMMENT = 'Incident identifier'
   , incident_comment_history.author_id AS author_id
      COMMENT = 'Comment author user id'
   , incident_comment_history.content AS content
      WITH SYNONYMS = ('comment', 'comment text')
      COMMENT = 'Comment content'
   , incident_comment_history.created_at AS created_at
      COMMENT = 'Comment creation timestamp'
    
   , quaterly_review_metrics.filename AS filename
      COMMENT = 'Source document filename parsed from relative_path'
   , quaterly_review_metrics.metric AS metric
      WITH SYNONYMS = ('metric key', 'kpi')
      COMMENT = 'Metric key extracted from the JSON response'
   , quaterly_review_metrics.value AS value
      WITH SYNONYMS = ('metric value', 'kpi value')
      COMMENT = 'Metric value (string) extracted from the JSON response'
   , quaterly_review_metrics.created_at AS created_at
      COMMENT = 'Record creation timestamp'

   , users.email AS email
      WITH SYNONYMS = ('email', 'email address')
      COMMENT = 'Primary email address'
   , users.first_name AS first_name
      WITH SYNONYMS = ('first name')
      COMMENT = 'First name parsed from email user part'
   , users.last_name AS last_name
      WITH SYNONYMS = ('last name')
      COMMENT = 'Last name parsed from email domain part'
   , users.role AS role
      COMMENT = 'User role'
   , users.department AS department
      COMMENT = 'User department'
   , users.team AS team
      COMMENT = 'User team'
   , users.is_active AS is_active
      COMMENT = 'Active flag'
  )
