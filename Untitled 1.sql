use database incident_management;
use schema bronze_zone;



create or replace stream bronze_zone.documents_stream
on stage bronze_zone.documents;

select * from documents_stream;


select * from v_qualify_new_documents;


select 
question_extracts_json
from document_question_extracts;
