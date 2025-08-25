# Incident Management Dashboard

A modular, multi-page Streamlit application for visualizing incident management metrics and analytics.

## Architecture

The application uses a **modular page system** where each page is a separate Python module in the `pages/` directory. This allows for:

- **Easy maintenance**: Each page is isolated in its own module
- **Dynamic loading**: Pages are loaded dynamically by the main app
- **Extensibility**: New pages can be added by creating new modules
- **Code organization**: Clean separation of concerns

## Features

### 🚨 Dashboard Page (`pages/dashboard.py`)
- **Key Metrics Tiles**: Active incidents, critical incidents, SLA status, resolution time, and resolution rate
- **Monthly Trends**: Line chart showing incident volume over time
- **Weekly Trends**: Bar chart with critical incident overlay
- **Category Performance**: Horizontal bar chart and scatter plot analysis
- **Priority Distribution**: Pie chart of incident priorities
- **SLA Status**: Bar chart of SLA compliance
- **Active Incidents Table**: Filterable table with detailed incident information

### 🖼️ Image Comparison Page (`pages/image_comparison.py`)
- **Side-by-side Image Display**: Compare two images simultaneously
- **Image Selection**: Dropdown menus to select images from the data/images directory
- **Image Information**: Display dimensions and metadata
- **Comparison Tools**: Notes, analysis, and save functionality

### 📊 Analytics Page (`pages/analytics.py`)
- **Advanced KPIs**: Detailed performance indicators with trend analysis
- **Time Series Analysis**: Interactive date range selection and trend visualization
- **Team Performance**: Multi-dimensional team efficiency analysis
- **Statistical Summary**: Correlation analysis and trend detection

## Installation

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

2. Run the Streamlit app:
```bash
streamlit run main.py
```

## File Structure

```
streamlit/
├── main.py                      # Main application with dynamic page loading
├── requirements.txt             # Python dependencies
├── README.md                   # This file
└── pages/                      # Modular page components
    ├── __init__.py             # Package initialization
    ├── dashboard.py            # Main dashboard page
    ├── image_comparison.py     # Image comparison functionality
    └── analytics.py            # Advanced analytics page
```

## Adding New Pages

To add a new page to the application:

1. **Create a new module** in the `pages/` directory (e.g., `pages/reports.py`)

2. **Implement a `render()` function** in your module:
```python
def render():
    st.title("📊 My New Page")
    st.write("Page content goes here...")
```

3. **Register the page** in `main.py` by adding it to the `PAGE_REGISTRY`:
```python
PAGE_REGISTRY = {
    "🚨 Dashboard": "dashboard",
    "🖼️ Image Comparison": "image_comparison", 
    "📊 Analytics": "analytics",
    "📊 Reports": "reports"  # Add your new page here
}
```

4. **Restart the app** and your new page will appear in the sidebar navigation!

## Dynamic Page Loading

The main application (`main.py`) uses Python's `importlib` to dynamically load page modules at runtime. This provides several benefits:

- **Performance**: Only the selected page is loaded into memory
- **Modularity**: Each page is completely independent
- **Error Isolation**: Issues in one page don't affect others
- **Development**: Pages can be developed and tested independently

## Data Sources

The application currently uses sample data for demonstration. In production, you would:

- **Replace sample data functions** with database connections
- **Connect to DBT curated zone models** for real incident metrics
- **Integrate with external APIs** for real-time data
- **Add authentication** for secure data access

## Customization

- **Styling**: Modify CSS in `main.py` for global styles, or add page-specific styles in individual modules
- **Charts**: Each page module can use any visualization library (Plotly, Matplotlib, Altair, etc.)
- **Data Processing**: Add utility modules for data processing and transformation
- **Configuration**: Add environment variables or config files for different deployment environments

## Navigation

The application features a dynamic sidebar that:
- **Auto-generates navigation** from the page registry
- **Shows current page status** and application information
- **Provides contextual help** and usage information
- **Updates timestamps** and connection status
