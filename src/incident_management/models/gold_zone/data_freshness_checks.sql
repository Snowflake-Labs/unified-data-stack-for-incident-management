config(
    materialized='view'
    ,description='View to check the data freshness of the incidents table'
    ,tags=['data_freshness_checks']
)

SELECT
    SCHEDULED_TIME,
    MEASUREMENT_TIME,
    TABLE_DATABASE,
    TABLE_SCHEMA,
    TABLE_NAME,
    METRIC_NAME,
    VALUE
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE UPPER(TABLE_NAME) IN ({{var('dmf_freshness_tables')}})
  AND UPPER(METRIC_NAME) LIKE '%FRESHNESS%'
ORDER BY MEASUREMENT_TIME DESC;