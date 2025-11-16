-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
        
    

    

    merge into v1_incident_management.gold_zone.incident_comment_history as DBT_INTERNAL_DEST
        using v1_incident_management.gold_zone.incident_comment_history__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.id = DBT_INTERNAL_DEST.id
                )

    
    when matched then update set
        created_at = DBT_INTERNAL_SOURCE.created_at,content = DBT_INTERNAL_SOURCE.content,author_id = DBT_INTERNAL_SOURCE.author_id,incident_number = DBT_INTERNAL_SOURCE.incident_number
    

    when not matched then insert
        ("ID", "INCIDENT_NUMBER", "AUTHOR_ID", "CONTENT", "CREATED_AT")
    values
        ("ID", "INCIDENT_NUMBER", "AUTHOR_ID", "CONTENT", "CREATED_AT")

;
    commit;