select 
*
from silver_zone.document_question_extracts;

select 
*
from gold_zone.quaterly_review_metrics;

select 
parse_json(incident_number):incident_code as c1,
IS_NULL_VALUE(parse_json(incident_number):incident_code) as c2,
nvl(c1,'null value') as c3
from incident_management.bronze_zone.v_qualify_slack_messages;