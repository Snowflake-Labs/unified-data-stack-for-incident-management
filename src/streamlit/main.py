"""
Incident Management Dashboard - Single Page Streamlit Application
"""

from dataclasses import dataclass
import json
from typing import List, Optional
import streamlit as st
from datetime import datetime, timedelta
import pandas as pd
from snowflake.snowpark.session import Session
from snowflake.snowpark.context import get_active_session
from snowflake.core import Root
import requests
from dotenv import load_dotenv
import os

# Constants and utilities merged from app_utils.py
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
                    # TODO: Add validation for connection parameters
                    self.snowpark_session = Session.builder.configs({k: v for k, v in kwargs.items() if v is not None and v != ""}).create()
                    self.snowflake_root = Root(self.snowpark_session)
                else:
                    load_dotenv()
                    
                    # Read from environment variables if no connection parameters are provided using .env file
                    connection_parameters = {
                        "account": os.getenv("DBT_SNOWFLAKE_ACCOUNT"),
                        "user": os.getenv("SNOWFLAKE_USER"),
                        "password": os.getenv("DBT_SNOWFLAKE_PASSWORD"),
                        "role": os.getenv("DBT_PROJECT_ADMIN_ROLE"), 
                        "warehouse": os.getenv("STREAMLIT_QUERY_WH"),  # optional
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


def connect_to_snowflake(**kwargs):
    session, root = SnowflakeConnection().connect(**kwargs)
    return session, root


def execute_sql(sql: str, session: Session) -> pd.DataFrame:
    rows = session.sql(sql).collect()
    res = []
    for row in rows:
        res.append(row.as_dict(True))
    return pd.DataFrame(res)


def ask_cortex(prompt: str, session: Session, model: str = "claude-4-sonnet") -> str:
    # Send a POST request to the Cortex Inference API endpoint
    HOST = os.getenv("SNOWFLAKE_HOST", f'{session.get_current_account()}.snowflakecomputing.com')
    PAT = os.getenv("SNOWFLAKE_USER_PAT")

    resp = requests.post(
        url=f"https://{HOST}/api/v2/cortex/inference:complete",
        json={"messages": [{"role": "user", "content": prompt}], "model": model, "stream": False},
        headers={
            "Authorization": f'Bearer {PAT}',
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Content-Type": "application/json",
        },
    )
    try:
        response_body = resp.json()
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


def submit_feedback(session: Session, request_id: str, positive: bool, feedback_message: str) -> Optional[str]:
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

# Page configuration
st.set_page_config(
    page_title="Incident Management Dashboard",
    page_icon="🚨",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# st.logo("snowflake.png")

def initialize_session_state():
    if "snowpark_session" not in st.session_state:
        snowflake_connection = SnowflakeConnection()
        ## if you're running this locally, make sure you export env variables from the .env file
        st.session_state.snowpark_session, st.session_state.snowflake_root = snowflake_connection.connect()



def create_header():
    """Create the main dashboard header"""
    
    col1, col2 = st.columns([1, 10])
    
    with col1:
        st.markdown("""
        <div style="
            width: 80px; 
            height: 80px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 28px;
            margin-top: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        ">
            🚨
        </div>
        """, unsafe_allow_html=True)
    
    with col2:
        st.markdown("""
        <div style="padding-left: 20px;">
            <h1 style="margin: 0; color: #1e40af; font-size: 2.5rem; font-weight: 700;">
                Incident Management Dashboard
            </h1>
            <p style="margin: 5px 0; color: #6b7280; font-size: 1.2rem;">
                Monitor, track, and analyze incidents across your organization in real-time
            </p>
        </div>
        """, unsafe_allow_html=True)

def create_metrics_cards():
    """Create key metrics cards"""

    try:
        database = st.session_state.snowpark_session.get_current_database()
        schema = "gold_zone"
        
        # Calculate current metrics
        total_active = execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents", st.session_state.snowpark_session)
        critical_count = execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents WHERE lower(priority) = 'critical'", st.session_state.snowpark_session)
        high_count = execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents WHERE lower(priority) = 'high'", st.session_state.snowpark_session)
        closed_count = execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.closed_incidents WHERE closed_at >= DATEADD('day', -30, CURRENT_DATE())", st.session_state.snowpark_session)
    except Exception as e:
        total_active = pd.DataFrame({"COUNT": 0}, index=[0])
        critical_count = pd.DataFrame({"COUNT": 0}, index=[0])
        high_count = pd.DataFrame({"COUNT": 0}, index=[0])
        closed_count = pd.DataFrame({"COUNT": 0}, index=[0])
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.markdown("""
        <div style="
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            text-align: center;
            border-left: 4px solid #dc2626;
        ">
            <h3 style="margin: 0; color: #991b1b; font-size: 0.95rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Critical Incidents</h3>
            <h1 style="margin: 15px 0 10px 0; color: #dc2626; font-size: 3rem; font-weight: 700;">{}</h1>
            <p style="margin: 0; color: #991b1b; font-size: 0.85rem; font-weight: 500;">Immediate attention required</p>
        </div>
        """.format(critical_count['COUNT'][0]), unsafe_allow_html=True)
    
    with col2:
        st.markdown("""
        <div style="
            background: linear-gradient(135deg, #fefbf2 0%, #fef3c7 100%);
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            text-align: center;
            border-left: 4px solid #f59e0b;
        ">
            <h3 style="margin: 0; color: #92400e; font-size: 0.95rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">High Priority</h3>
            <h1 style="margin: 15px 0 10px 0; color: #f59e0b; font-size: 3rem; font-weight: 700;">{}</h1>
            <p style="margin: 0; color: #92400e; font-size: 0.85rem; font-weight: 500;">Requires urgent action</p>
        </div>
        """.format(high_count['COUNT'][0]), unsafe_allow_html=True)
    
    with col3:
        st.markdown("""
        <div style="
            background: linear-gradient(135deg, #f0f9ff 0%, #dbeafe 100%);
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            text-align: center;
            border-left: 4px solid #3b82f6;
        ">
            <h3 style="margin: 0; color: #1e40af; font-size: 0.95rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Total Active</h3>
            <h1 style="margin: 15px 0 10px 0; color: #3b82f6; font-size: 3rem; font-weight: 700;">{}</h1>
            <p style="margin: 0; color: #1e40af; font-size: 0.85rem; font-weight: 500;">Currently being worked on</p>
        </div>
        """.format(total_active['COUNT'][0]), unsafe_allow_html=True)
    
    with col4:
        st.markdown("""
        <div style="
            background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            text-align: center;
            border-left: 4px solid #10b981;
        ">
            <h3 style="margin: 0; color: #065f46; font-size: 0.95rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Closed (30 days)</h3>
            <h1 style="margin: 15px 0 10px 0; color: #10b981; font-size: 3rem; font-weight: 700;">{}</h1>
            <p style="margin: 0; color: #065f46; font-size: 0.85rem; font-weight: 500;">Successfully resolved</p>
        </div>
        """.format(closed_count['COUNT'][0]), unsafe_allow_html=True)
    

def create_charts():
    """Create dashboard charts using real data from the database"""
    
    database = st.session_state.snowpark_session.get_current_database()
    schema = "gold_zone"
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.subheader("📈 Monthly Incident Trends")
        try:
            # Get monthly trends data
            monthly_query = f"""
                SELECT 
                    month,
                    total_incidents,
                    critical_incidents,
                    high_priority_incidents
                FROM {database}.{schema}.monthly_incident_trends
                ORDER BY month DESC
                LIMIT 12
            """
            monthly_df = execute_sql(monthly_query, st.session_state.snowpark_session)
            
            if not monthly_df.empty:
                import altair as alt
                chart = alt.Chart(monthly_df).mark_line(
                    color='#3b82f6',
                    strokeWidth=3,
                    point=True
                ).encode(
                    x=alt.X('MONTH:T', title='Month'),
                    y=alt.Y('TOTAL_INCIDENTS:Q', title='Total Incidents'),
                    tooltip=['MONTH:T', 'TOTAL_INCIDENTS:Q']
                ).properties(   
                    height=400
                ).configure_axis(
                    grid=True,
                    gridColor='#f3f4f6'
                )
                st.altair_chart(chart, use_container_width=True)
            else:
                st.info("No monthly trend data available")
        except Exception as e:
            st.error(f"Error loading monthly trends: {str(e)}")
    
    with col2:
        st.subheader("🎯 Weekly Incident Trends")
        try:
            # Get weekly trends data
            weekly_query = f"""
                SELECT 
                    week,
                    total_incidents,
                    critical_incidents,
                    high_incidents
                FROM {database}.{schema}.weekly_incident_trends
                ORDER BY week DESC
                LIMIT 12
            """
            weekly_df = execute_sql(weekly_query, st.session_state.snowpark_session)
            
            if not weekly_df.empty:
                import altair as alt
                chart = alt.Chart(weekly_df).mark_line(
                    color='#10b981',
                    strokeWidth=3,
                    point=True
                ).encode(
                    x=alt.X('WEEK:T', title='Week'),
                    y=alt.Y('TOTAL_INCIDENTS:Q', title='Total Incidents'),
                    tooltip=['WEEK:T', 'TOTAL_INCIDENTS:Q']
                ).properties(
                    height=400
                ).configure_axis(
                    grid=True,
                    gridColor='#f3f4f6'
                )
                st.altair_chart(chart, use_container_width=True)
            else:
                st.info("No weekly trend data available")
        except Exception as e:
            st.error(f"Error loading weekly trends: {str(e)}")
    
    with col3:
        st.subheader("🎯 Incidents by Category - To date")
        try:
            # Get category breakdown from current incidents
            category_query = f"""
                SELECT 
                    category,
                    COUNT(*) as incident_count
                FROM {database}.gold_zone.incidents
                GROUP BY category
                ORDER BY incident_count DESC
            """
            category_df = execute_sql(category_query, st.session_state.snowpark_session)
            
            if not category_df.empty:
                import plotly.graph_objects as go
                fig = go.Figure(data=[
                    go.Pie(
                        labels=category_df['CATEGORY'],
                        values=category_df['INCIDENT_COUNT'],
                        hole=0.4,
                        marker=dict(
                            colors=['#dc2626', '#f59e0b', '#3b82f6', '#10b981', '#8b5cf6', '#ef4444', '#06b6d4']
                        )
                    )
                ])
                
                fig.update_layout(
                    height=400,
                    margin=dict(l=40, r=40, t=40, b=40),
                    paper_bgcolor='rgba(0,0,0,0)',
                    showlegend=True,
                    legend=dict(
                        orientation="v",
                        yanchor="middle",
                        y=0.5,
                        xanchor="left",
                        x=1.05
                    )
                )
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.info("No category data available")
        except Exception as e:
            st.error(f"Error loading category data: {str(e)}")


def get_incident_attachments(incident_id):
    """Fetch attachments for a specific incident"""
    database = st.session_state.snowpark_session.get_current_database()
    schema = "gold_zone"
    
    # Query to get attachments for the incident
    query = f"""
    SELECT 
        attachment_file,
        uploaded_at
    FROM {database}.{schema}.incident_attachments 
    WHERE incident_number = '{incident_id}'
    ORDER BY uploaded_at DESC
    """
    
    try:
        attachments = execute_sql(query, st.session_state.snowpark_session)
        return attachments
    except Exception as e:
        st.error(f"Error fetching attachments: {str(e)}")
        return pd.DataFrame()

def create_attachments_popover(incident_id, title):
    """Create a popover to display attachments for an incident"""
    with st.popover(f"📎 Attachments - {incident_id}", use_container_width=True):
        
        # Fetch attachments
        attachments = get_incident_attachments(incident_id)
        
        if not attachments.empty:
            st.markdown(f"**Found {len(attachments)} attachment(s):**")
            
            for idx, attachment in attachments.iterrows():
                with st.container():
                    img=st.session_state.snowpark_session.file.get_stream(attachment["ATTACHMENT_FILE"], decompress=False).read()

                    st.image(img, width=300, use_container_width="never")

                    st.caption(f"Uploaded: {attachment['UPLOADED_AT']}")
                    
                    if idx < len(attachments) - 1:
                        st.markdown("---")
        else:
            st.info("No attachments found for this incident.")

def create_active_incidents_table():
    """Create active incidents table"""
    
    st.subheader("🔄 Top 5 Active Incidents")

    try:
        database = st.session_state.snowpark_session.get_current_database()
        schema = "gold_zone"
            # Convert to DataFrame
        df = execute_sql(f"""
                WITH latest_created_at AS (
                    SELECT
                        incident_number,
                        MAX(created_at) AS latest_created_at
                    FROM
                        gold_zone.incident_comment_history
                    GROUP BY
                        incident_number
                ),
                latest_comments AS (
                    SELECT
                        ich.incident_number,
                        ich.created_at,
                        ich.content AS latest_comment
                    FROM
                        gold_zone.incident_comment_history AS ich
                        INNER JOIN latest_created_at AS lc ON ich.incident_number = lc.incident_number
                    AND ich.created_at = lc.latest_created_at
                    ORDER BY
                        ich.created_at DESC
                )
                SELECT 
                    ai."INCIDENT_NUMBER", 
                    ai."TITLE", 
                    ai."PRIORITY", 
                    ai."STATUS", 
                    ai."CATEGORY", 
                    ai."CREATED_AT", 
                    ai."ASSIGNEE_ID",
                    ai."ASSIGNEE_NAME", 
                    ai."HAS_ATTACHMENTS",
                    ai."SOURCE_SYSTEM",
                    ai."EXTERNAL_SOURCE_ID",
                    lc."LATEST_COMMENT" as "LAST_COMMENT"
                FROM {database}.{schema}.active_incidents ai 
                LEFT JOIN latest_comments lc ON ai.incident_number = lc.incident_number
                ORDER BY ai.created_at DESC 
                LIMIT 5
        """, st.session_state.snowpark_session)
    except Exception as e:
        df = pd.DataFrame()

    if df.empty:
        st.info("No active incidents found.")
        return
    
    # Define priority colors
    def get_priority_color(priority):
        colors = {
            "critical": "🔴",
            "high": "🟡", 
            "medium": "🔵",
            "low": "🟢"
        }
        return colors.get(priority.lower(), "⚪")
    
    # Add priority icons
    df["PRIORITY"] = df["PRIORITY"].apply(lambda x: f"{get_priority_color(x)} {x}")
        # Convert HAS_ATTACHMENTS to icons
    def get_attachment_icon(has_attachments):
        return "📎" if has_attachments else "—"
        
    df["HAS_ATTACHMENTS"] = df["HAS_ATTACHMENTS"].apply(get_attachment_icon)

    # Display the dataframe
    active_incidents = st.dataframe(
        df[["INCIDENT_NUMBER", "TITLE", "PRIORITY", "STATUS", "CATEGORY", "CREATED_AT", "ASSIGNEE_NAME", "HAS_ATTACHMENTS", "SOURCE_SYSTEM", "LAST_COMMENT"]],
        use_container_width=True,
        column_config={
            "INCIDENT_NUMBER": st.column_config.TextColumn("Incident ID", width="small"),
            "TITLE": st.column_config.TextColumn("Title", width="large"),
            "PRIORITY": st.column_config.TextColumn("Priority", width="small"),
            "STATUS": st.column_config.TextColumn("Status", width="small"),
            "CATEGORY": st.column_config.TextColumn("Category", width="small"),
            "CREATED_AT": st.column_config.DatetimeColumn("Created", width="medium"),
            "ASSIGNEE_NAME": st.column_config.TextColumn("Assigned To", width="medium"),
            "HAS_ATTACHMENTS": st.column_config.TextColumn("Has attachments?", width="small"),
            "SOURCE_SYSTEM": st.column_config.TextColumn("Source", width="small"),
            "LAST_COMMENT": st.column_config.TextColumn("Last Comment", width="large"),
        },
        selection_mode="single-row",
        hide_index=True,
        on_select="rerun",
        key="incidents_table"
    )
    
    # Handle row selection for attachments popover
    if active_incidents.selection.rows:
        selected_row_idx = active_incidents.selection.rows[0]
        selected_incident = df.iloc[selected_row_idx]
        
        if selected_incident['HAS_ATTACHMENTS']:
            st.markdown("### 📎 Attachments")
            create_attachments_popover(selected_incident['INCIDENT_NUMBER'], selected_incident['TITLE'])


def create_recently_closed_incidents_table():
    """Display table of recently closed incidents"""
    st.subheader("🎯 Last known Closed Incidents")

    try:
        database = st.session_state.snowpark_session.get_current_database()
        schema = "gold_zone"

        # Get last 5 closed incidents from the new closed_incidents model
        query = f"""
            SELECT 
                incident_number,
                title,
                priority,
                category,
                status,
                closed_at,
                created_at,
                total_resolution_hours,
                source_system,
                has_attachments
            FROM {database}.{schema}.closed_incidents
            ORDER BY closed_at DESC
            LIMIT 5
        """
        closed_incidents = execute_sql(query, st.session_state.snowpark_session)
    except Exception as e:
        closed_incidents = pd.DataFrame()

    if closed_incidents.empty:
        st.info("No recently closed incidents found.")
        return

    if not closed_incidents.empty:
        # Add priority colors
        def get_priority_color(priority):
            colors = {
                "critical": "🔴",
                "high": "🟡", 
                "medium": "🔵",
                "low": "🟢"
            }
            return colors.get(priority.lower(), "⚪")
        
        def get_status_icon(status):
            icons = {
                "closed": "✅",
                "resolved": "🎯"
            }
            return icons.get(status.lower(), "❓")
        
        # Add icons to the dataframe
        closed_incidents["PRIORITY"] = closed_incidents["PRIORITY"].apply(
            lambda x: f"{get_priority_color(x)} {x}"
        )
        closed_incidents["STATUS"] = closed_incidents["STATUS"].apply(
            lambda x: f"{get_status_icon(x)} {x}"
        )
        
        # Convert HAS_ATTACHMENTS to icons
        def get_attachment_icon(has_attachments):
            return "📎" if has_attachments else "—"
        
        closed_incidents["HAS_ATTACHMENTS"] = closed_incidents["HAS_ATTACHMENTS"].apply(get_attachment_icon)
        
        st.dataframe(
            closed_incidents,
            column_config={
                "INCIDENT_NUMBER": st.column_config.TextColumn("Incident #", width="small"),
                "TITLE": st.column_config.TextColumn("Title", width="large"),
                "PRIORITY": st.column_config.TextColumn("Priority", width="small"),
                "CATEGORY": st.column_config.TextColumn("Category", width="small"), 
                "STATUS": st.column_config.TextColumn("Status", width="small"),
                "CREATED_AT": st.column_config.DatetimeColumn("Created At", width="medium"),
                "CLOSED_AT": st.column_config.DatetimeColumn("Closed At", width="medium"),
                "TOTAL_RESOLUTION_HOURS": st.column_config.NumberColumn("Resolution (hrs)", width="small", format="%.1f"),
                "SOURCE_SYSTEM": st.column_config.TextColumn("Source", width="small"),
                "HAS_ATTACHMENTS": st.column_config.TextColumn("Attachments", width="small")
            },
            hide_index=True,
            use_container_width=True
        )
    else:
        st.info("No recently closed incidents found.")


def create_documents_processed_tab():
    """Display documents processed in full and for Q&A"""
    
    database = st.session_state.snowpark_session.get_current_database()
    schema = "silver_zone"
    
    # Section 1: Documents Processed in Full
    st.markdown("### 📄 Documents Processed in Full")
    st.markdown("Documents that have been fully parsed and split into semantic chunks")
    
    try:
        # Query to get documents with chunk counts
        full_docs_query = f"""
            SELECT 
                RELATIVE_PATH,
                EXTENSION,
                SIZE,
                LAST_MODIFIED,
                COUNT(*) as CHUNK_COUNT
            FROM {database}.{schema}.document_full_extracts
            GROUP BY RELATIVE_PATH, EXTENSION, SIZE, LAST_MODIFIED
            ORDER BY LAST_MODIFIED DESC
        """
        full_docs_df = execute_sql(full_docs_query, st.session_state.snowpark_session)
        
        if not full_docs_df.empty:
            # Format file size to be more readable
            full_docs_df['SIZE_MB'] = (full_docs_df['SIZE'] / 1024 / 1024).round(2)
            
            st.dataframe(
                full_docs_df[['RELATIVE_PATH', 'EXTENSION', 'SIZE_MB', 'CHUNK_COUNT', 'LAST_MODIFIED']],
                column_config={
                    "RELATIVE_PATH": st.column_config.TextColumn("Document Path", width="large"),
                    "EXTENSION": st.column_config.TextColumn("Type", width="small"),
                    "SIZE_MB": st.column_config.NumberColumn("Size (MB)", width="small", format="%.2f"),
                    "CHUNK_COUNT": st.column_config.NumberColumn("Chunks Extracted", width="medium"),
                    "LAST_MODIFIED": st.column_config.DatetimeColumn("Last Modified", width="medium"),
                },
                hide_index=True,
                use_container_width=True
            )
            
            # Summary metrics for full documents
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("Total Documents", len(full_docs_df))
            with col2:
                st.metric("Total Chunks", full_docs_df['CHUNK_COUNT'].sum())
            with col3:
                st.metric("Avg Chunks per Doc", int(full_docs_df['CHUNK_COUNT'].mean()))
        else:
            st.info("No documents processed in full yet.")
    except Exception as e:
        st.error(f"Error loading full documents: {str(e)}")
    
    st.markdown("<br><br>", unsafe_allow_html=True)
    
    # Section 2: Documents Processed for Q&A
    st.markdown("### ❓ Documents Processed for Q&A")
    st.markdown("Documents that have been analyzed for question extraction using AI")
    
    try:
        # Query to get documents processed for Q&A
        qa_docs_query = f"""
            SELECT 
                RELATIVE_PATH,
                EXTENSION,
                SIZE,
                LAST_MODIFIED,
                ANALYSIS_TYPE
            FROM {database}.{schema}.document_question_extracts
            ORDER BY LAST_MODIFIED DESC
        """
        qa_docs_df = execute_sql(qa_docs_query, st.session_state.snowpark_session)
        
        if not qa_docs_df.empty:
            # Format file size to be more readable
            qa_docs_df['SIZE_MB'] = (qa_docs_df['SIZE'] / 1024 / 1024).round(2)
            
            st.dataframe(
                qa_docs_df[['RELATIVE_PATH', 'EXTENSION', 'SIZE_MB', 'ANALYSIS_TYPE', 'LAST_MODIFIED']],
                column_config={
                    "RELATIVE_PATH": st.column_config.TextColumn("Document Path", width="large"),
                    "EXTENSION": st.column_config.TextColumn("Type", width="small"),
                    "SIZE_MB": st.column_config.NumberColumn("Size (MB)", width="small", format="%.2f"),
                    "ANALYSIS_TYPE": st.column_config.TextColumn("Analysis Type", width="medium"),
                    "LAST_MODIFIED": st.column_config.DatetimeColumn("Last Modified", width="medium"),
                },
                hide_index=True,
                use_container_width=True
            )
            
            # Summary metrics for Q&A documents
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Total Documents", len(qa_docs_df))
            with col2:
                # Count by analysis type
                analysis_counts = qa_docs_df.groupby('ANALYSIS_TYPE').size()
                if len(analysis_counts) > 0:
                    st.metric(f"Question Analysis", analysis_counts.get('question', 0))
        else:
            st.info("No documents processed for Q&A yet.")
    except Exception as e:
        st.error(f"Error loading Q&A documents: {str(e)}")


def main():

    initialize_session_state()
    
    # Custom CSS
    st.markdown("""
    <style>
    /* Global styles */
    .main > div {
        padding-top: 2rem;
    }
    
    .main .block-container {
        padding-top: 2rem;
        padding-bottom: 2rem;
    }
    
    /* Hide Streamlit menu and footer */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    
    /* Custom styling */
    .stDataFrame {
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        overflow: hidden;
    }
    
    .js-plotly-plot {
        border-radius: 8px;
        background: white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    }
    
    /* Section spacing */
    .element-container {
        margin-bottom: 1rem;
    }
    </style>
    """, unsafe_allow_html=True)
    
    
    # Header section
    create_header()
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    # Create tabs
    tab1, tab2 = st.tabs(["📊 Dashboard", "📚 Documents Processed"])
    
    with tab1:
        # Key metrics
        create_metrics_cards()
        
        st.markdown("<br><br>", unsafe_allow_html=True)
        
        # # Charts section
        # create_charts()
        
        # st.markdown("<br>", unsafe_allow_html=True)
        
        
        # Active incidents table
        create_active_incidents_table()
        
        st.markdown("<br>", unsafe_allow_html=True)

        # Recently closed incidents table
        create_recently_closed_incidents_table()
        st.markdown("<br>", unsafe_allow_html=True)
    
    with tab2:
        create_documents_processed_tab()
        st.markdown("<br>", unsafe_allow_html=True)

    # Footer with refresh
    st.markdown("---")
    col1, col2 = st.columns([3, 1])
    with col1:
        current_time = datetime.now().strftime("%B %d, %Y at %H:%M:%S")
        st.caption(f"📅 Last updated: {current_time}")
    with col2:
        if st.button("🔄 Refresh Data", type="secondary"):
            st.rerun()

if __name__ == "__main__":
    main()