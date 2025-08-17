# Incident Management Dashboard

A multi-page Streamlit application for visualizing incident management metrics and comparing incident-related images.

## Features

### 📊 Dashboard Page
- **Key Metrics Tiles**: Active incidents, critical incidents, SLA status, resolution time, and resolution rate
- **Monthly Trends**: Line chart showing incident volume over time
- **Weekly Trends**: Bar chart with critical incident overlay
- **Category Performance**: Horizontal bar chart and scatter plot analysis
- **Priority Distribution**: Pie chart of incident priorities
- **SLA Status**: Bar chart of SLA compliance
- **Active Incidents Table**: Filterable table with detailed incident information

### 🖼️ Image Comparison Page
- **Side-by-side Image Display**: Compare two images simultaneously
- **Image Selection**: Dropdown menus to select images from the data/images directory
- **Image Information**: Display dimensions and metadata
- **Comparison Tools**: Notes, analysis, and save functionality (placeholder features)

## Installation

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

2. Run the Streamlit app:
```bash
streamlit run main.py
```

## Data Source

The dashboard currently uses sample data for demonstration purposes. In a production environment, this would be connected to:
- DBT curated zone models for incident metrics
- Database connections for real-time data
- File system or cloud storage for images

## File Structure

```
streamlit/
├── main.py              # Main Streamlit application
├── requirements.txt     # Python dependencies
└── README.md           # This file
```

## Customization

- **Data Connection**: Replace the `create_sample_data()` function with actual database connections
- **Styling**: Modify the CSS in the main.py file to customize appearance
- **Charts**: Add or modify Plotly charts in the dashboard functions
- **Image Sources**: Update image directory path or add cloud storage integration

## Navigation

Use the sidebar to navigate between:
- **Dashboard**: Main incident metrics and analytics
- **Image Comparison**: Side-by-side image comparison tool
