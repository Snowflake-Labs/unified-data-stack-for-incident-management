-- Integration test: every incident attachment must reference a valid incident
-- Returns failing rows (attachments with no matching incident)
select ia.id, ia.incident_number
from {{ ref('incident_attachments') }} ia
left join {{ ref('incidents') }} i
  on ia.incident_number = i.incident_number
where i.incident_number is null
