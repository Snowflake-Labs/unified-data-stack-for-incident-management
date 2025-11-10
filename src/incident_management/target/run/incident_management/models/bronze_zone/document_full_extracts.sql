begin;
    insert into incident_management.bronze_zone.document_full_extracts ("RELATIVE_PATH", "SIZE", "LAST_MODIFIED", "MD5", "ETAG", "FILE_URL", "DOC_TYPE", "EXTENSION", "PAGE_NUM", "CHUNK", "HEADERS")
    (
        select "RELATIVE_PATH", "SIZE", "LAST_MODIFIED", "MD5", "ETAG", "FILE_URL", "DOC_TYPE", "EXTENSION", "PAGE_NUM", "CHUNK", "HEADERS"
        from incident_management.bronze_zone.document_full_extracts__dbt_tmp
    )

;
    commit;