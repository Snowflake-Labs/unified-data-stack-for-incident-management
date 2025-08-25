"""
Analytics page module for the Incident Management Streamlit app
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from datetime import datetime, timedelta


def create_analytics_data():
    """Create sample analytics data"""
    np.random.seed(123)
    
    # Time series data for detailed analytics
    dates = pd.date_range(start='2024-01-01', end='2024-12-31', freq='D')
    daily_data = pd.DataFrame({
        'date': dates,
        'incidents_created': np.random.poisson(3, len(dates)),
        'incidents_resolved': np.random.poisson(2.8, len(dates)),
        'mttr_hours': np.random.lognormal(2, 0.5, len(dates)),
        'customer_satisfaction': np.random.normal(4.2, 0.3, len(dates))
    })
    
    # Team performance data
    teams = ['Backend', 'Frontend', 'DevOps', 'Database', 'Security', 'QA']
    team_data = pd.DataFrame({
        'team': teams,
        'incidents_handled': np.random.poisson(25, len(teams)),
        'avg_resolution_time': np.random.normal(12, 4, len(teams)),
        'satisfaction_score': np.random.uniform(3.8, 4.8, len(teams)),
        'sla_compliance': np.random.uniform(85, 98, len(teams))
    })
    
    return daily_data, team_data


def render():
    """Render the analytics page"""
    
    st.title("📊 Advanced Analytics")
    st.markdown("Deep dive into incident management performance metrics")
    st.markdown("---")
    
    # Get analytics data
    daily_data, team_data = create_analytics_data()
    
    # Time period selector
    col1, col2 = st.columns(2)
    with col1:
        start_date = st.date_input(
            "Start Date",
            value=datetime(2024, 10, 1),
            min_value=datetime(2024, 1, 1),
            max_value=datetime(2024, 12, 31)
        )
    with col2:
        end_date = st.date_input(
            "End Date", 
            value=datetime(2024, 12, 31),
            min_value=datetime(2024, 1, 1),
            max_value=datetime(2024, 12, 31)
        )
    
    # Filter data by date range
    filtered_data = daily_data[
        (daily_data['date'] >= pd.Timestamp(start_date)) & 
        (daily_data['date'] <= pd.Timestamp(end_date))
    ]
    
    st.markdown("---")
    
    # KPI Cards
    st.subheader("🎯 Key Performance Indicators")
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        total_incidents = filtered_data['incidents_created'].sum()
        st.metric("Total Incidents", total_incidents)
    
    with col2:
        avg_mttr = filtered_data['mttr_hours'].mean()
        st.metric("Avg MTTR", f"{avg_mttr:.1f}h")
    
    with col3:
        resolution_rate = (filtered_data['incidents_resolved'].sum() / total_incidents * 100) if total_incidents > 0 else 0
        st.metric("Resolution Rate", f"{resolution_rate:.1f}%")
    
    with col4:
        avg_satisfaction = filtered_data['customer_satisfaction'].mean()
        st.metric("Customer Satisfaction", f"{avg_satisfaction:.2f}/5")
    
    st.markdown("---")
    
    # Trend Analysis
    st.subheader("📈 Trend Analysis")
    
    # Create subplot with secondary y-axis
    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=('Incident Volume Over Time', 'MTTR Trend', 
                       'Resolution Rate Trend', 'Customer Satisfaction Trend'),
        specs=[[{"secondary_y": True}, {"secondary_y": False}],
               [{"secondary_y": False}, {"secondary_y": False}]]
    )
    
    # Incident volume
    fig.add_trace(
        go.Scatter(x=filtered_data['date'], y=filtered_data['incidents_created'], 
                  name='Created', line=dict(color='red')),
        row=1, col=1
    )
    fig.add_trace(
        go.Scatter(x=filtered_data['date'], y=filtered_data['incidents_resolved'], 
                  name='Resolved', line=dict(color='green')),
        row=1, col=1
    )
    
    # MTTR trend
    fig.add_trace(
        go.Scatter(x=filtered_data['date'], y=filtered_data['mttr_hours'], 
                  name='MTTR', line=dict(color='orange')),
        row=1, col=2
    )
    
    # Resolution rate
    resolution_rate_daily = filtered_data['incidents_resolved'] / filtered_data['incidents_created'] * 100
    fig.add_trace(
        go.Scatter(x=filtered_data['date'], y=resolution_rate_daily, 
                  name='Resolution Rate', line=dict(color='blue')),
        row=2, col=1
    )
    
    # Customer satisfaction
    fig.add_trace(
        go.Scatter(x=filtered_data['date'], y=filtered_data['customer_satisfaction'], 
                  name='Satisfaction', line=dict(color='purple')),
        row=2, col=2
    )
    
    fig.update_layout(height=600, showlegend=False)
    st.plotly_chart(fig, use_container_width=True)
    
    st.markdown("---")
    
    # Team Performance Analysis
    st.subheader("👥 Team Performance Analysis")
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Team workload
        fig_workload = px.bar(
            team_data.sort_values('incidents_handled', ascending=True),
            x='incidents_handled',
            y='team',
            orientation='h',
            title="Incidents Handled by Team",
            color='incidents_handled',
            color_continuous_scale='viridis'
        )
        fig_workload.update_layout(height=400)
        st.plotly_chart(fig_workload, use_container_width=True)
    
    with col2:
        # Team efficiency scatter plot
        fig_efficiency = px.scatter(
            team_data,
            x='avg_resolution_time',
            y='satisfaction_score',
            size='incidents_handled',
            color='sla_compliance',
            hover_data=['team'],
            title="Team Efficiency: Resolution Time vs Satisfaction",
            labels={
                'avg_resolution_time': 'Avg Resolution Time (hours)',
                'satisfaction_score': 'Customer Satisfaction Score'
            }
        )
        fig_efficiency.update_layout(height=400)
        st.plotly_chart(fig_efficiency, use_container_width=True)
    
    # Detailed team table
    st.subheader("📋 Team Performance Details")
    
    # Format the team data for display
    display_data = team_data.copy()
    display_data['avg_resolution_time'] = display_data['avg_resolution_time'].round(1)
    display_data['satisfaction_score'] = display_data['satisfaction_score'].round(2)
    display_data['sla_compliance'] = display_data['sla_compliance'].round(1)
    
    st.dataframe(
        display_data.rename(columns={
            'team': 'Team',
            'incidents_handled': 'Incidents Handled',
            'avg_resolution_time': 'Avg Resolution Time (h)',
            'satisfaction_score': 'Satisfaction Score',
            'sla_compliance': 'SLA Compliance (%)'
        }),
        use_container_width=True,
        height=250
    )
    
    st.markdown("---")
    
    # Statistical Summary
    st.subheader("📈 Statistical Summary")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.write("**Incident Volume Statistics**")
        st.write(f"- Mean daily incidents: {filtered_data['incidents_created'].mean():.1f}")
        st.write(f"- Peak daily incidents: {filtered_data['incidents_created'].max()}")
        st.write(f"- Standard deviation: {filtered_data['incidents_created'].std():.1f}")
        
        st.write("**MTTR Statistics**")
        st.write(f"- Mean MTTR: {filtered_data['mttr_hours'].mean():.1f} hours")
        st.write(f"- Median MTTR: {filtered_data['mttr_hours'].median():.1f} hours")
        st.write(f"- 95th percentile: {filtered_data['mttr_hours'].quantile(0.95):.1f} hours")
    
    with col2:
        st.write("**Performance Trends**")
        
        # Calculate trend (simple linear regression slope)
        incidents_trend = np.polyfit(range(len(filtered_data)), filtered_data['incidents_created'], 1)[0]
        mttr_trend = np.polyfit(range(len(filtered_data)), filtered_data['mttr_hours'], 1)[0]
        satisfaction_trend = np.polyfit(range(len(filtered_data)), filtered_data['customer_satisfaction'], 1)[0]
        
        st.write(f"- Incident volume trend: {'📈' if incidents_trend > 0 else '📉'} {incidents_trend:.3f} per day")
        st.write(f"- MTTR trend: {'📈' if mttr_trend > 0 else '📉'} {mttr_trend:.3f} hours per day")
        st.write(f"- Satisfaction trend: {'📈' if satisfaction_trend > 0 else '📉'} {satisfaction_trend:.3f} per day")
        
        # Show correlation
        correlation = filtered_data[['incidents_created', 'mttr_hours', 'customer_satisfaction']].corr()
        st.write("**Key Correlations**")
        st.write(f"- Incidents vs MTTR: {correlation.loc['incidents_created', 'mttr_hours']:.2f}")
        st.write(f"- MTTR vs Satisfaction: {correlation.loc['mttr_hours', 'customer_satisfaction']:.2f}")

