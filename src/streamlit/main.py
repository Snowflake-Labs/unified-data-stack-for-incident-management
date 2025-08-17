"""
Incident Management Dashboard - Multi-page Streamlit Application
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from datetime import datetime, timedelta
import os
from PIL import Image

# Page configuration
st.set_page_config(
    page_title="Incident Management Dashboard",
    page_icon="🚨",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .metric-tile {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
        margin-bottom: 1rem;
    }
    .critical-tile {
        border-left-color: #d62728;
    }
    .warning-tile {
        border-left-color: #ff7f0e;
    }
    .success-tile {
        border-left-color: #2ca02c;
    }
    .stTabs [data-baseweb="tab-list"] button [data-testid="stMarkdownContainer"] p {
        font-size: 1.1rem;
        font-weight: 600;
    }
</style>
""", unsafe_allow_html=True)

def create_sample_data():
    """Create sample data for demonstration purposes"""
    
    # Sample data for different metrics
    np.random.seed(42)
    
    # Monthly trends data
    months = pd.date_range(start='2024-01-01', end='2024-12-01', freq='MS')
    monthly_data = pd.DataFrame({
        'month': months,
        'total_incidents': np.random.poisson(25, len(months)),
        'resolved_incidents': np.random.poisson(20, len(months)),
        'critical_incidents': np.random.poisson(3, len(months)),
        'high_priority_incidents': np.random.poisson(7, len(months)),
        'sla_breaches': np.random.poisson(2, len(months)),
        'avg_resolution_time_hours': np.random.normal(8, 2, len(months)),
        'resolution_rate_percentage': np.random.uniform(75, 95, len(months))
    })
    
    # Weekly trends data
    weeks = pd.date_range(start='2024-10-01', end='2024-12-31', freq='W')
    weekly_data = pd.DataFrame({
        'week': weeks,
        'total_incidents': np.random.poisson(6, len(weeks)),
        'resolved_incidents': np.random.poisson(5, len(weeks)),
        'critical_incidents': np.random.poisson(1, len(weeks)),
        'sla_breaches': np.random.poisson(1, len(weeks)),
        'avg_resolution_time_hours': np.random.normal(7, 1.5, len(weeks))
    })
    
    # Category performance data
    categories = ['Authentication', 'Payment Gateway', 'Database', 'API', 'UI/UX', 'Infrastructure']
    category_data = pd.DataFrame({
        'category_name': categories,
        'total_incidents': np.random.poisson(15, len(categories)),
        'resolved_incidents': np.random.poisson(12, len(categories)),
        'resolution_rate_percentage': np.random.uniform(70, 95, len(categories)),
        'avg_resolution_time_hours': np.random.normal(8, 3, len(categories)),
        'critical_incidents': np.random.poisson(2, len(categories)),
        'sla_breaches': np.random.poisson(1, len(categories))
    })
    
    # Active incidents data
    active_data = pd.DataFrame({
        'incident_number': [f'INC-{i:04d}' for i in range(101, 121)],
        'title': [f'Sample Incident {i}' for i in range(1, 21)],
        'priority': np.random.choice(['critical', 'high', 'medium', 'low'], 20, p=[0.1, 0.3, 0.5, 0.1]),
        'category_name': np.random.choice(categories, 20),
        'age_hours': np.random.exponential(24, 20),
        'sla_status': np.random.choice(['ON_TRACK', 'DUE_SOON', 'OVERDUE'], 20, p=[0.6, 0.3, 0.1]),
        'affected_customers_count': np.random.poisson(50, 20),
        'estimated_revenue_impact': np.random.exponential(5000, 20)
    })
    
    return {
        'monthly_trends': monthly_data,
        'weekly_trends': weekly_data,
        'category_performance': category_data,
        'active_incidents': active_data
    }

def render_dashboard():
    """Render the main dashboard page"""
    
    st.title("🚨 Incident Management Dashboard")
    st.markdown("---")
    
    # Get sample data
    data = create_sample_data()
    
    # Key Metrics Row
    st.subheader("📊 Key Metrics")
    
    col1, col2, col3, col4, col5 = st.columns(5)
    
    with col1:
        total_active = len(data['active_incidents'])
        st.metric(
            label="Active Incidents",
            value=total_active,
            delta=f"+{np.random.randint(-3, 5)} from last week"
        )
    
    with col2:
        critical_count = len(data['active_incidents'][data['active_incidents']['priority'] == 'critical'])
        st.metric(
            label="Critical Incidents",
            value=critical_count,
            delta=f"{np.random.randint(-2, 3)} from last week",
            delta_color="inverse"
        )
    
    with col3:
        overdue_count = len(data['active_incidents'][data['active_incidents']['sla_status'] == 'OVERDUE'])
        st.metric(
            label="SLA Overdue",
            value=overdue_count,
            delta=f"{np.random.randint(-1, 2)} from last week",
            delta_color="inverse"
        )
    
    with col4:
        avg_resolution = data['monthly_trends']['avg_resolution_time_hours'].iloc[-1]
        st.metric(
            label="Avg Resolution Time",
            value=f"{avg_resolution:.1f}h",
            delta=f"{np.random.uniform(-1, 1):.1f}h from last month"
        )
    
    with col5:
        resolution_rate = data['monthly_trends']['resolution_rate_percentage'].iloc[-1]
        st.metric(
            label="Resolution Rate",
            value=f"{resolution_rate:.1f}%",
            delta=f"{np.random.uniform(-2, 3):.1f}% from last month"
        )
    
    st.markdown("---")
    
    # Charts Row 1
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📈 Monthly Incident Trends")
        fig_monthly = px.line(
            data['monthly_trends'], 
            x='month', 
            y=['total_incidents', 'resolved_incidents', 'critical_incidents'],
            title="Monthly Incident Volume",
            labels={'value': 'Count', 'month': 'Month'}
        )
        fig_monthly.update_layout(height=400)
        st.plotly_chart(fig_monthly, use_container_width=True)
    
    with col2:
        st.subheader("⚡ Weekly Trends (Last 12 weeks)")
        fig_weekly = px.bar(
            data['weekly_trends'], 
            x='week', 
            y='total_incidents',
            color='critical_incidents',
            title="Weekly Incident Volume with Critical Incidents",
            labels={'total_incidents': 'Total Incidents', 'week': 'Week'}
        )
        fig_weekly.update_layout(height=400)
        st.plotly_chart(fig_weekly, use_container_width=True)
    
    # Charts Row 2
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("🏷️ Category Performance")
        fig_category = px.bar(
            data['category_performance'].sort_values('total_incidents', ascending=True),
            x='total_incidents',
            y='category_name',
            orientation='h',
            title="Incidents by Category",
            labels={'total_incidents': 'Total Incidents', 'category_name': 'Category'}
        )
        fig_category.update_layout(height=400)
        st.plotly_chart(fig_category, use_container_width=True)
    
    with col2:
        st.subheader("🎯 Resolution Rate by Category")
        fig_resolution = px.scatter(
            data['category_performance'],
            x='avg_resolution_time_hours',
            y='resolution_rate_percentage',
            size='total_incidents',
            color='sla_breaches',
            hover_data=['category_name'],
            title="Resolution Time vs Rate",
            labels={'avg_resolution_time_hours': 'Avg Resolution Time (hours)', 
                   'resolution_rate_percentage': 'Resolution Rate (%)'}
        )
        fig_resolution.update_layout(height=400)
        st.plotly_chart(fig_resolution, use_container_width=True)
    
    # Charts Row 3
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("🚨 Priority Distribution")
        priority_counts = data['active_incidents']['priority'].value_counts()
        fig_priority = px.pie(
            values=priority_counts.values,
            names=priority_counts.index,
            title="Active Incidents by Priority",
            color_discrete_map={
                'critical': '#d62728',
                'high': '#ff7f0e', 
                'medium': '#2ca02c',
                'low': '#1f77b4'
            }
        )
        fig_priority.update_layout(height=400)
        st.plotly_chart(fig_priority, use_container_width=True)
    
    with col2:
        st.subheader("⏰ SLA Status Overview")
        sla_counts = data['active_incidents']['sla_status'].value_counts()
        fig_sla = px.bar(
            x=sla_counts.index,
            y=sla_counts.values,
            title="SLA Status Distribution",
            color=sla_counts.index,
            color_discrete_map={
                'ON_TRACK': '#2ca02c',
                'DUE_SOON': '#ff7f0e',
                'OVERDUE': '#d62728'
            }
        )
        fig_sla.update_layout(height=400, showlegend=False)
        st.plotly_chart(fig_sla, use_container_width=True)
    
    # Active Incidents Table
    st.markdown("---")
    st.subheader("🔍 Active Incidents Details")
    
    # Add filters
    col1, col2, col3 = st.columns(3)
    with col1:
        priority_filter = st.selectbox(
            "Filter by Priority",
            options=['All'] + list(data['active_incidents']['priority'].unique()),
            index=0
        )
    with col2:
        category_filter = st.selectbox(
            "Filter by Category",
            options=['All'] + list(data['active_incidents']['category_name'].unique()),
            index=0
        )
    with col3:
        sla_filter = st.selectbox(
            "Filter by SLA Status",
            options=['All'] + list(data['active_incidents']['sla_status'].unique()),
            index=0
        )
    
    # Apply filters
    filtered_data = data['active_incidents'].copy()
    if priority_filter != 'All':
        filtered_data = filtered_data[filtered_data['priority'] == priority_filter]
    if category_filter != 'All':
        filtered_data = filtered_data[filtered_data['category_name'] == category_filter]
    if sla_filter != 'All':
        filtered_data = filtered_data[filtered_data['sla_status'] == sla_filter]
    
    # Display filtered table
    st.dataframe(
        filtered_data[['incident_number', 'title', 'priority', 'category_name', 
                      'age_hours', 'sla_status', 'affected_customers_count', 
                      'estimated_revenue_impact']].round(2),
        use_container_width=True,
        height=300
    )

def render_image_comparison():
    """Render the image comparison page"""
    
    st.title("🖼️ Image Comparison")
    st.markdown("Compare incident-related images side by side")
    st.markdown("---")
    
    # Image directory path
    image_dir = "/Users/clakkad/Documents/Work/publish/incident-management/data/images"
    
    # Get available images
    image_files = [f for f in os.listdir(image_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    if not image_files:
        st.warning("No images found in the data/images directory.")
        st.info("Please add some images to the directory to use the comparison feature.")
        return
    
    # Image selection
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📋 Left Image")
        left_image = st.selectbox(
            "Select first image:",
            options=image_files,
            key="left_image"
        )
    
    with col2:
        st.subheader("📋 Right Image")
        right_image = st.selectbox(
            "Select second image:",
            options=image_files,
            key="right_image"
        )
    
    # Display images side by side
    if left_image and right_image:
        st.markdown("---")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader(f"🖼️ {left_image}")
            try:
                left_img = Image.open(os.path.join(image_dir, left_image))
                st.image(left_img, use_column_width=True, caption=left_image)
                
                # Display image info
                st.info(f"**Dimensions:** {left_img.size[0]} x {left_img.size[1]} pixels")
                
            except Exception as e:
                st.error(f"Error loading {left_image}: {str(e)}")
        
        with col2:
            st.subheader(f"🖼️ {right_image}")
            try:
                right_img = Image.open(os.path.join(image_dir, right_image))
                st.image(right_img, use_column_width=True, caption=right_image)
                
                # Display image info
                st.info(f"**Dimensions:** {right_img.size[0]} x {right_img.size[1]} pixels")
                
            except Exception as e:
                st.error(f"Error loading {right_image}: {str(e)}")
    
    # Additional comparison features
    st.markdown("---")
    st.subheader("🔍 Comparison Tools")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        if st.button("📝 Add Notes"):
            st.text_area("Comparison Notes:", 
                        placeholder="Add your observations about the image comparison...",
                        height=100)
    
    with col2:
        if st.button("📊 Image Analysis"):
            st.info("Image analysis features could be added here (size, format, metadata, etc.)")
    
    with col3:
        if st.button("💾 Save Comparison"):
            st.success("Comparison saved! (Feature to be implemented)")

def main():
    """Main application function"""
    
    # Sidebar navigation
    st.sidebar.title("🚨 Navigation")
    st.sidebar.markdown("---")
    
    # Page selection
    page = st.sidebar.selectbox(
        "Select Page:",
        options=["Dashboard", "Image Comparison"],
        index=0
    )
    
    # Additional sidebar info
    st.sidebar.markdown("---")
    st.sidebar.subheader("📊 App Info")
    st.sidebar.info("**Incident Management Dashboard**\n\n"
                   "- **Dashboard**: View incident metrics and analytics\n"
                   "- **Image Comparison**: Compare incident-related images")
    
    st.sidebar.markdown("---")
    st.sidebar.caption(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Render selected page
    if page == "Dashboard":
        render_dashboard()
    elif page == "Image Comparison":
        render_image_comparison()

if __name__ == "__main__":
    main()
