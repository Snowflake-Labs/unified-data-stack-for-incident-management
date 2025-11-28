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


CREATE OR REPLACE FUNCTION read_stage_file(file_path STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
HANDLER = 'read_file_from_stage'
PACKAGES = ('snowflake-snowpark-python')
AS
$$
from snowflake.snowpark.files import SnowflakeFile

def read_file_from_stage(file_path: str) -> str:
    """
    Reads a file from a Snowflake stage and returns its contents as a string.
    
    Parameters:
    -----------
    file_path : str
        The full path to the file in the stage (e.g., '@my_stage/folder/file.txt')
        
    Returns:
    --------
    str
        The contents of the file as a string
        
    Example:
    --------
    SELECT read_stage_file('@my_stage/data/sample.txt');
    """
    try:
        with SnowflakeFile.open(file_path, 'r') as f:
            contents = f.read()
        return contents
    except Exception as e:
        return f"Error reading file: {str(e)}"
$$;

select build_scoped_file_url(@incident_management.gold_zone.agent_specs, 'packages.yml');

   EXECUTE IMMEDIATE $$
   BEGIN
    LET file_path STRING := build_scoped_file_url(@incident_management.gold_zone.agent_specs, 'packages.yml');
    LET agent_spec STRING := INCIDENT_MANAGEMENT.DBT_PROJECT_DEPLOYMENTS.read_stage_file(:file_path);
    RETURN agent_spec;
   END;
   $$;

   