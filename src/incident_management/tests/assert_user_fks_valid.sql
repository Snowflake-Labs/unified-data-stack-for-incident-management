-- Integration test: assignee_id and reportee_id in incidents must reference valid users
-- Returns failing rows (incidents with invalid user references)
-- Check reportee_id (assignee_id can be empty string for unassigned)
select i.incident_number, i.reportee_id as invalid_user_id, 'reportee_id' as fk_field
from {{ ref('incidents') }} i
left join {{ ref('users') }} u
  on i.reportee_id = u.id
where i.reportee_id is not null
  and i.reportee_id != ''
  and u.id is null

union all

-- Check assignee_id (only when non-empty)
select i.incident_number, i.assignee_id as invalid_user_id, 'assignee_id' as fk_field
from {{ ref('incidents') }} i
left join {{ ref('users') }} u
  on i.assignee_id = u.id
where i.assignee_id is not null
  and i.assignee_id != ''
  and u.id is null
