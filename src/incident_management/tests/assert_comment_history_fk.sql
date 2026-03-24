-- Integration test: every comment history entry must reference a valid incident
-- Returns failing rows (comments with no matching incident)
select ch.id, ch.incident_number
from {{ ref('incident_comment_history') }} ch
left join {{ ref('incidents') }} i
  on ch.incident_number = i.incident_number
where i.incident_number is null
