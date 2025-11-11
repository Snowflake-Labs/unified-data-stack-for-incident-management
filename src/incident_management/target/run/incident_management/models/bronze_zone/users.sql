-- back compat for old kwarg name
  
  begin;
    
        
            
	    
	    
            
        
    

    

    merge into v1_incident_management.bronze_zone.users as DBT_INTERNAL_DEST
        using v1_incident_management.bronze_zone.users__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.email = DBT_INTERNAL_DEST.email))

    
    when matched then update set
        "ID" = DBT_INTERNAL_SOURCE."ID","EMAIL" = DBT_INTERNAL_SOURCE."EMAIL","FIRST_NAME" = DBT_INTERNAL_SOURCE."FIRST_NAME","LAST_NAME" = DBT_INTERNAL_SOURCE."LAST_NAME","ROLE" = DBT_INTERNAL_SOURCE."ROLE","DEPARTMENT" = DBT_INTERNAL_SOURCE."DEPARTMENT","TEAM" = DBT_INTERNAL_SOURCE."TEAM","IS_ACTIVE" = DBT_INTERNAL_SOURCE."IS_ACTIVE","UPDATED_AT" = DBT_INTERNAL_SOURCE."UPDATED_AT"
    

    when not matched then insert
        ("ID", "EMAIL", "FIRST_NAME", "LAST_NAME", "ROLE", "DEPARTMENT", "TEAM", "IS_ACTIVE", "CREATED_AT", "UPDATED_AT")
    values
        ("ID", "EMAIL", "FIRST_NAME", "LAST_NAME", "ROLE", "DEPARTMENT", "TEAM", "IS_ACTIVE", "CREATED_AT", "UPDATED_AT")

;
    commit;