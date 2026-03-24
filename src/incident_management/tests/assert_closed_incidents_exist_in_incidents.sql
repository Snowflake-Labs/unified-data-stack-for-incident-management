-- Integration test: every closed incident must exist in the incidents table
-- Returns failing rows (closed incidents with no matching incident)
select ci.incident_number
from {{ ref('closed_incidents') }} ci
left join {{ ref('incidents') }} i
  on ci.incident_number = i.incident_number
where i.incident_number is null
