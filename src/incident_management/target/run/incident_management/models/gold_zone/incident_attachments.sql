-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
        
    

    

    merge into v1_incident_management.gold_zone.incident_attachments as DBT_INTERNAL_DEST
        using v1_incident_management.gold_zone.incident_attachments__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.id = DBT_INTERNAL_DEST.id
                )

    
    when matched then update set
        uploaded_at = DBT_INTERNAL_SOURCE.uploaded_at,attachment_file = DBT_INTERNAL_SOURCE.attachment_file
    

    when not matched then insert
        ("ID", "INCIDENT_NUMBER", "ATTACHMENT_FILE", "UPLOADED_AT")
    values
        ("ID", "INCIDENT_NUMBER", "ATTACHMENT_FILE", "UPLOADED_AT")

;
    commit;