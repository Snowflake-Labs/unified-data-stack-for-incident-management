-- Integration test: every active incident must exist in the incidents table
-- Returns failing rows (active incidents with no matching incident)
select ai.incident_number
from {{ ref('active_incidents') }} ai
left join {{ ref('incidents') }} i
  on ai.incident_number = i.incident_number
where i.incident_number is null
