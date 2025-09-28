"""
Incident Management Dashboard - Single Page Streamlit Application
"""

import streamlit as st
from datetime import datetime, timedelta
import app_utils as au
import pandas as pd

# Page configuration
st.set_page_config(
    page_title="Incident Management Dashboard",
    page_icon="🚨",
    layout="wide",
    initial_sidebar_state="collapsed"
)

st.logo("snowflake.png")

def initialize_session_state():
    if "snowpark_session" not in st.session_state:
        snowflake_connection = au.SnowflakeConnection()
        ## if you're running this locally, make sure you export env variables from the .env file
        st.session_state.snowpark_session, st.session_state.snowflake_root = snowflake_connection.connect()
        st.session_state.snowpark_session.use_schema("landing_zone")


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
        schema = "curated_zone"
        
        # Calculate current metrics
        total_active = au.execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents", st.session_state.snowpark_session)
        critical_count = au.execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents WHERE lower(priority) = 'critical'", st.session_state.snowpark_session)
        high_count = au.execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.active_incidents WHERE lower(priority) = 'high'", st.session_state.snowpark_session)
        closed_count = au.execute_sql(f"SELECT COUNT(*) as count FROM {database}.{schema}.closed_incidents WHERE closed_at >= DATEADD('day', -30, CURRENT_DATE())", st.session_state.snowpark_session)
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
    schema = "curated_zone"
    
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
            monthly_df = au.execute_sql(monthly_query, st.session_state.snowpark_session)
            
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
            weekly_df = au.execute_sql(weekly_query, st.session_state.snowpark_session)
            
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
                FROM {database}.landing_zone.incidents
                GROUP BY category
                ORDER BY incident_count DESC
            """
            category_df = au.execute_sql(category_query, st.session_state.snowpark_session)
            
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
    schema = "landing_zone"
    
    # Query to get attachments for the incident
    query = f"""
    SELECT 
        attachment_file,
        '@{database}.{schema}.DOCUMENTS' as documents_stage,
        fl_get_relative_path(attachment_file) as attachment_file_path,
        uploaded_at
    FROM {database}.landing_zone.incident_attachments 
    WHERE incident_number = '{incident_id}'
    ORDER BY uploaded_at DESC
    """
    
    try:
        attachments = au.execute_sql(query, st.session_state.snowpark_session)
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
                    img=st.session_state.snowpark_session.file.get_stream(f'{attachment["DOCUMENTS_STAGE"]}/{attachment["ATTACHMENT_FILE_PATH"]}', decompress=False).read()

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
        schema = "curated_zone"
            # Convert to DataFrame
        df = au.execute_sql(f"""
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
            ic."CONTENT" as "LAST_COMMENT"
        FROM {database}.{schema}.active_incidents ai 
        LEFT JOIN {database}.landing_zone.incident_comment_history ic ON ai.incident_number = ic.incident_number
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
    st.subheader("🎯 Recently Closed Incidents")

    try:
        database = st.session_state.snowpark_session.get_current_database()
        schema = "curated_zone"

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
        closed_incidents = au.execute_sql(query, st.session_state.snowpark_session)
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