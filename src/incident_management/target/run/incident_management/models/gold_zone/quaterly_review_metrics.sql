-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
        
    

    

    merge into incident_management.gold_zone.quaterly_review_metrics as DBT_INTERNAL_DEST
        using incident_management.gold_zone.quaterly_review_metrics__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.filename = DBT_INTERNAL_DEST.filename
                )

    
    when matched then update set
        "FILENAME" = DBT_INTERNAL_SOURCE."FILENAME","METRIC" = DBT_INTERNAL_SOURCE."METRIC","VALUE" = DBT_INTERNAL_SOURCE."VALUE"
    

    when not matched then insert
        ("FILENAME", "METRIC", "VALUE", "CREATED_AT")
    values
        ("FILENAME", "METRIC", "VALUE", "CREATED_AT")

;
    commit;