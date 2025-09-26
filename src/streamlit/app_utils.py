from dataclasses import dataclass
import json
from typing import List, Optional
import pandas as pd
from snowflake.snowpark.session import Session
from snowflake.snowpark.context import get_active_session
from snowflake.cortex import complete
from snowflake.core import Root
import requests
from dotenv import load_dotenv
import os


API_TIMEOUT = 50000  # in milliseconds
FEEDBACK_API_ENDPOINT = "/api/v2/cortex/analyst/feedback"


class SnowflakeConnectionException(Exception):
    """Custom exception for Snowflake connection errors."""
    pass


@dataclass
class SnowflakeConnection:

    """
    SnowflakeConnection class to connect to Snowflake using Snowpark and Snowflake Root.

    You can set the config using few different ways if running externally from Snowflake:
    - If you set the connection parameters using kwargs, they will take precedence over the .env file.
    - If you do not set the connection parameters using kwargs, the .env file will be used.
    - If you do not set the connection parameters using kwargs or the .env file, the connection will be established using the active Snowpark session.
    - If you do not have an active Snowpark session, the connection will be established using the .env file.
    - If you do not have an active Snowpark session and the .env file is not set, the connection will fail.

    If running from Snowflake, the connection will be established using the active Snowpark session.
    If you do not have an active Snowpark session, the connection will fail.
    
    Args:
        **kwargs: Connection parameters including:
            - account: Snowflake account identifier
            - user: Username
            - password: Programmatic Access Token
            - role: User role 
            - warehouse: Default warehouse (optional)
            - database: Default database (optional)
            - schema: Default schema (optional)
    """

    def connect(self, **kwargs) -> List:
        try:
            try:
                self.snowpark_session = get_active_session()   
                if self.snowpark_session is None:
                    raise SnowflakeConnectionException("No active Snowpark session found")  
                else:
                    self.snowflake_root = Root(self.snowpark_session)
            except Exception as e:
                if len(kwargs) > 0:
                    ## TODO: Add validation for connection parameters                        
                    self.snowpark_session = Session.builder.configs({k:v for k,v in kwargs.items() if v is not None and v != ""}).create()
                    self.snowflake_root = Root(self.snowpark_session)
                else:
                    ## Read from environment variables if no connection parameters are provided using .env file
                    connection_parameters = {
                        "account": os.getenv("DBT_SNOWFLAKE_ACCOUNT"),
                        "user": os.getenv("DBT_SNOWFLAKE_USER"),
                        "password": os.getenv("DBT_SNOWFLAKE_PASSWORD"),
                        "role": os.getenv("DBT_PROJECT_ADMIN_ROLE"), 
                        "warehouse": os.getenv("DBT_SNOWFLAKE_WAREHOUSE"),  # optional
                        "database": os.getenv("DBT_PROJECT_DATABASE"),  # optional
                        "schema": os.getenv("DBT_PROJECT_SCHEMA"),  # optional
                    }
                    self.snowpark_session = Session.builder.configs(connection_parameters).create()
                    self.snowflake_root = Root(self.snowpark_session)
        except Exception as e:
            raise e
        
        return [self.snowpark_session, self.snowflake_root]

    def disconnect(self):
        self.snowpark_session.close()

######
### Business logic functions
######


def connect_to_snowflake(**kwargs):
    session, root = SnowflakeConnection().connect(**kwargs)
    return session, root

def execute_sql(sql: str, session: Session) -> pd.DataFrame:
    rows =  session.sql(sql).collect()
    res=[]
    for row in rows:
        res.append(row.as_dict(True))
    return pd.DataFrame(res)

def ask_cortex(prompt: str, session: Session, model: str = "claude-4-sonnet") -> str:

    # Send a POST request to the Cortex Inference API endpoint
    HOST = os.getenv("SNOWFLAKE_HOST", f'{session.get_current_account()}.snowflakecomputing.com')
    PAT = os.getenv("SNOWFLAKE_USER_PAT")

    resp =  requests.post(
        url=f"https://{HOST}/api/v2/cortex/inference:complete",
        json={"messages": [{"role": "user", "content": prompt}], "model": model, "stream": False},
        headers={
            "Authorization": f'Bearer {PAT}',
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Content-Type": "application/json",
        },
    )
    try:
        response_body  = resp.json()
        return response_body
    except Exception as e:
        return f"Error: {e}"

def ask_cortex_analyst(prompt: str, session: Session, semantic_view: str) -> str:
    # Prepare the request body with the user's prompt
    request_body = {
        "messages": [{"role": "user", "content": [{"type": "text", "text": prompt}]}],
        "semantic_view": f"{semantic_view}",
    }

    # Send a POST request to the Cortex Analyst API endpoint
    HOST = os.getenv("SNOWFLAKE_HOST", f'{session.get_current_account()}.snowflakecomputing.com')
    PAT = os.getenv("SNOWFLAKE_USER_PAT")
    
    resp = requests.post(
        url=f"https://{HOST}/api/v2/cortex/analyst/message",
        json=request_body,
        headers={
            "Authorization": f'Bearer {PAT}',
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Content-Type": "application/json",
        },
    )
    
    if resp.status_code < 400:
        request_id = resp.headers.get("X-Snowflake-Request-Id")
        return {**resp.json(), "request_id": request_id}  # type: ignore[arg-type]
    else:
        # Craft readable error message
        request_id = resp.headers.get("X-Snowflake-Request-Id")
        error_msg = f"""
                    🚨 An Analyst API error has occurred 🚨

                    * response code: `{resp.status_code}`
                    * request-id: `{request_id}`
                    * error: `{resp.text}`
            """
        raise Exception(error_msg)


def submit_feedback(session: Session,
    request_id: str, positive: bool, feedback_message: str
) -> Optional[str]:
    
    request_body = {
        "request_id": request_id,
        "positive": positive,
        "feedback_message": feedback_message,
    }
    
    # Send a POST request to the Cortex Analyst API endpoint
    HOST = os.getenv("SNOWFLAKE_HOST", f'{session.get_current_account()}.snowflakecomputing.com')
    PAT = os.getenv("SNOWFLAKE_USER_PAT")

    resp = requests.post(
        url=f"https://{HOST}/api/v2/cortex/analyst/feedback",
        json=request_body,
        headers={
            "Authorization": f'Bearer {PAT}',
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Content-Type": "application/json",
        },
        timeout=API_TIMEOUT
    )
    
    if resp.status_code == 200:
        return None

    parsed_content = json.loads(resp.content)
    
    # Craft readable error message
    err_msg = f"""
        🚨 An Analyst API error has occurred 🚨
        
        * response code: `{resp.status_code}`
        * request-id: `{parsed_content['request_id']}`
        * error code: `{parsed_content['error_code']}`
        
        Message:
        ```
        {parsed_content['message']}
        ```
        """
    return err_msg
