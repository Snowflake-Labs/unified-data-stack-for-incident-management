-- back compat for old kwarg name
  
  begin;
    
        
            
	    
	    
            
        
    

    

    merge into incident_management.gold_zone.incidents as DBT_INTERNAL_DEST
        using incident_management.gold_zone.incidents__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.incident_number = DBT_INTERNAL_DEST.incident_number))

    
    when matched then update set
        updated_at = DBT_INTERNAL_SOURCE.updated_at,slack_message_id = DBT_INTERNAL_SOURCE.slack_message_id,last_comment = DBT_INTERNAL_SOURCE.last_comment
    

    when not matched then insert
        ("INCIDENT_NUMBER", "TITLE", "CATEGORY", "PRIORITY", "STATUS", "ASSIGNEE_ID", "REPORTEE_ID", "CREATED_AT", "CLOSED_AT", "UPDATED_AT", "SOURCE_SYSTEM", "EXTERNAL_SOURCE_ID", "HAS_ATTACHMENTS", "SLACK_MESSAGE_ID", "LAST_COMMENT")
    values
        ("INCIDENT_NUMBER", "TITLE", "CATEGORY", "PRIORITY", "STATUS", "ASSIGNEE_ID", "REPORTEE_ID", "CREATED_AT", "CLOSED_AT", "UPDATED_AT", "SOURCE_SYSTEM", "EXTERNAL_SOURCE_ID", "HAS_ATTACHMENTS", "SLACK_MESSAGE_ID", "LAST_COMMENT")

;
    commit;