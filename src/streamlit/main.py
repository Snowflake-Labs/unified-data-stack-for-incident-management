"""
Incident Management Dashboard - Single Page Streamlit Application
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime, timedelta
import random
import app_utils as au
import os

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
        st.session_state.snowpark_session, st.session_state.snowflake_root = snowflake_connection.connect()
def generate_sample_incident_data():
    """Generate sample incident data for the dashboard"""
    
    # Generate incident data for the last 30 days
    dates = pd.date_range(end=datetime.now(), periods=30, freq='D')
    
    # Sample incident counts by priority
    critical_incidents = [random.randint(0, 5) for _ in range(30)]
    high_incidents = [random.randint(2, 12) for _ in range(30)]
    medium_incidents = [random.randint(5, 25) for _ in range(30)]
    low_incidents = [random.randint(10, 40) for _ in range(30)]
    
    # Sample resolution times (in hours)
    resolution_times = [random.uniform(0.5, 48) for _ in range(30)]
    
    # Sample categories
    categories = ["Network", "Security", "Hardware", "Software", "Database", "API", "Infrastructure"]
    
    # Generate incidents by category
    incidents_by_category = {cat: random.randint(5, 50) for cat in categories}
    
    # Generate current active incidents
    active_incidents = []
    incident_ids = [f"INC{1000 + i}" for i in range(50)]
    
    for i in range(15):  # Generate 15 active incidents
        priority = random.choice(["Critical", "High", "Medium", "Low"])
        status = random.choice(["New", "In Progress", "Pending", "Investigating"])
        category = random.choice(categories)
        
        # Age in hours
        age_hours = random.randint(1, 72)
        created_time = datetime.now() - timedelta(hours=age_hours)
        
        active_incidents.append({
            "ID": incident_ids[i],
            "Title": f"{category} Issue - {random.choice(['Outage', 'Performance', 'Error', 'Failure'])}",
            "Priority": priority,
            "Status": status,
            "Category": category,
            "Created": created_time.strftime("%Y-%m-%d %H:%M"),
            "Age": f"{age_hours}h",
            "Assigned To": f"Team {random.choice(['Alpha', 'Beta', 'Gamma', 'Delta'])}"
        })
    
    # Generate hourly incident data for today
    hours = [f"{i:02d}:00" for i in range(24)]
    hourly_incidents = [random.randint(0, 8) for _ in range(24)]
    
    return {
        "dates": dates,
        "critical_incidents": critical_incidents,
        "high_incidents": high_incidents,
        "medium_incidents": medium_incidents,
        "low_incidents": low_incidents,
        "resolution_times": resolution_times,
        "incidents_by_category": incidents_by_category,
        "active_incidents": active_incidents,
        "hours": hours,
        "hourly_incidents": hourly_incidents
    }

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

    database = st.session_state.snowpark_session.get_current_database()
    schema = st.session_state.snowpark_session.get_current_schema()
    
    # Calculate current metrics
    total_active = au.execute_sql(f"SELECT COUNT(*) FROM {database}.{schema}.active_incidents", st.session_state.snowpark_session)
    critical_count = au.execute_sql(f"SELECT COUNT(*) FROM {database}.{schema}.active_incidents WHERE priority = 'Critical'", st.session_state.snowpark_session)
    high_count = au.execute_sql(f"SELECT COUNT(*) FROM {database}.{schema}.active_incidents WHERE priority = 'High'", st.session_state.snowpark_session)
    # avg_resolution = au.execute_sql(f"SELECT AVG(resolution_time) FROM {database}.{schema}.active_incidents", st.session_state.snowpark_session)
    
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
        """.format(critical_count), unsafe_allow_html=True)
    
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
        """.format(high_count), unsafe_allow_html=True)
    
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
        """.format(total_active), unsafe_allow_html=True)
    
    with col4:
        st.markdown("""
        <div style="
            background: linear-gradient(135deg, #f0fdf4 0%, #d1fae5 100%);
            padding: 25px; 
            border-radius: 12px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
            text-align: center;
            border-left: 4px solid #10b981;
        ">
            <h3 style="margin: 0; color: #065f46; font-size: 0.95rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Avg Resolution</h3>
            <h1 style="margin: 15px 0 10px 0; color: #10b981; font-size: 3rem; font-weight: 700;">{}</h1>
            <p style="margin: 0; color: #065f46; font-size: 0.85rem; font-weight: 500;">Target: < 4h</p>
        </div>
        """.format(avg_resolution), unsafe_allow_html=True)

def create_charts(data):
    """Create dashboard charts"""
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📈 Incident Trends (Last 30 Days)")
        
        fig1 = go.Figure()
        
        fig1.add_trace(go.Scatter(
            x=data["dates"],
            y=data["critical_incidents"],
            mode='lines+markers',
            name='Critical',
            line=dict(color='#dc2626', width=3),
            marker=dict(size=6)
        ))
        
        fig1.add_trace(go.Scatter(
            x=data["dates"],
            y=data["high_incidents"],
            mode='lines+markers',
            name='High',
            line=dict(color='#f59e0b', width=3),
            marker=dict(size=6)
        ))
        
        fig1.add_trace(go.Scatter(
            x=data["dates"],
            y=data["medium_incidents"],
            mode='lines+markers',
            name='Medium',
            line=dict(color='#3b82f6', width=3),
            marker=dict(size=6)
        ))
        
        fig1.add_trace(go.Scatter(
            x=data["dates"],
            y=data["low_incidents"],
            mode='lines+markers',
            name='Low',
            line=dict(color='#10b981', width=3),
            marker=dict(size=6)
        ))
        
        fig1.update_layout(
            height=400,
            margin=dict(l=40, r=40, t=40, b=40),
            xaxis_title="Date",
            yaxis_title="Number of Incidents",
            paper_bgcolor='rgba(0,0,0,0)',
            plot_bgcolor='rgba(0,0,0,0)',
            xaxis=dict(gridcolor='#f3f4f6'),
            yaxis=dict(gridcolor='#f3f4f6'),
            legend=dict(
                orientation="h",
                yanchor="bottom",
                y=1.02,
                xanchor="right",
                x=1
            )
        )
        
        st.plotly_chart(fig1, use_container_width=True)
    
    with col2:
        st.subheader("🎯 Incidents by Category")
        
        categories = list(data["incidents_by_category"].keys())
        values = list(data["incidents_by_category"].values())
        
        fig2 = go.Figure(data=[
            go.Pie(
                labels=categories,
                values=values,
                hole=0.4,
                marker=dict(
                    colors=['#dc2626', '#f59e0b', '#3b82f6', '#10b981', '#8b5cf6', '#ef4444', '#06b6d4']
                )
            )
        ])
        
        fig2.update_layout(
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
        
        st.plotly_chart(fig2, use_container_width=True)

def create_hourly_chart(data):
    """Create hourly incidents chart"""
    
    st.subheader("⏰ Incidents by Hour (Today)")
    
    fig = go.Figure(data=[
        go.Bar(
            x=data["hours"],
            y=data["hourly_incidents"],
            marker_color='#3b82f6',
            marker_line_color='#1d4ed8',
            marker_line_width=1,
            text=data["hourly_incidents"],
            textposition='auto',
        )
    ])
    
    fig.update_layout(
        height=300,
        margin=dict(l=40, r=40, t=40, b=40),
        xaxis_title="Hour",
        yaxis_title="Number of Incidents",
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        xaxis=dict(
            gridcolor='#f3f4f6',
            tickangle=45
        ),
        yaxis=dict(gridcolor='#f3f4f6'),
        showlegend=False
    )
    
    st.plotly_chart(fig, use_container_width=True)

def create_active_incidents_table(data):
    """Create active incidents table"""
    
    st.subheader("🔄 Top 5 Active Incidents")

    database = st.session_state.snowpark_session.get_current_database()
    schema = st.session_state.snowpark_session.get_current_schema()
    
    # Convert to DataFrame
    df = au.execute_sql(f"SELECT * FROM {database}.{schema}.active_incidents LIMIT 5 ORDER BY created_at DESC", st.session_state.snowpark_session)

    # Define priority colors
    def get_priority_color(priority):
        colors = {
            "Critical": "🔴",
            "High": "🟡", 
            "Medium": "🔵",
            "Low": "🟢"
        }
        return colors.get(priority, "⚪")
    
    # Add priority icons
    df["Priority"] = df["Priority"].apply(lambda x: f"{get_priority_color(x)} {x}")
    
    # Configure columns
    st.dataframe(
        df,
        use_container_width=True,
        height=400,
        column_config={
            "ID": st.column_config.TextColumn("Incident ID", width="small"),
            "Title": st.column_config.TextColumn("Title", width="large"),
            "Priority": st.column_config.TextColumn("Priority", width="small"),
            "Status": st.column_config.TextColumn("Status", width="small"),
            "Category": st.column_config.TextColumn("Category", width="small"),
            "Created": st.column_config.TextColumn("Created", width="medium"),
            "Age": st.column_config.TextColumn("Age", width="small"),
            "Assigned To": st.column_config.TextColumn("Assigned To", width="medium"),
        }
    )

def main():

    initialize_session_state()

    """Main application function"""
    
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
    
    # # Generate sample data
    # data = generate_sample_incident_data()
    
    # Header section
    create_header()
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    # Key metrics
    create_metrics_cards()
    
    st.markdown("<br><br>", unsafe_allow_html=True)
    
    # # Charts section
    # create_charts(data)
    
    # st.markdown("<br>", unsafe_allow_html=True)
    
    # # Hourly chart
    # create_hourly_chart(data)
    
    # st.markdown("<br>", unsafe_allow_html=True)
    
    # Active incidents table
    create_active_incidents_table(data)
    
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