begin;
    insert into incident_management.bronze_zone.document_question_extracts ("RELATIVE_PATH", "SIZE", "LAST_MODIFIED", "MD5", "ETAG", "FILE_URL", "DOC_TYPE", "EXTENSION", "QUESTION_EXTRACTS_JSON")
    (
        select "RELATIVE_PATH", "SIZE", "LAST_MODIFIED", "MD5", "ETAG", "FILE_URL", "DOC_TYPE", "EXTENSION", "QUESTION_EXTRACTS_JSON"
        from incident_management.bronze_zone.document_question_extracts__dbt_tmp
    )

;
    commit;