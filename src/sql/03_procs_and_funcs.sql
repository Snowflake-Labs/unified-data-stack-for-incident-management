use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- ============================================================================
-- Snowpark Python Function: Read File from Stage
-- ============================================================================

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

