"""
Incident Management Dashboard - Multi-page Streamlit Application
"""

import streamlit as st
import importlib
import sys
import os
from datetime import datetime

# Add the pages directory to the path
pages_dir = os.path.join(os.path.dirname(__file__), 'pages')
if pages_dir not in sys.path:
    sys.path.insert(0, pages_dir)

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
    .page-header {
        background: linear-gradient(90deg, #1f77b4, #2ca02c);
        padding: 1rem;
        border-radius: 0.5rem;
        color: white;
        margin-bottom: 1rem;
    }
</style>
""", unsafe_allow_html=True)


# Page registry - maps display names to module names
PAGE_REGISTRY = {
    "🚨 Dashboard": "dashboard",
    "🖼️ Image Comparison": "image_comparison", 
    "📊 Analytics": "analytics"
}


def load_page_module(module_name):
    """Dynamically load a page module"""
    try:
        # Try to import from pages directory
        module = importlib.import_module(f"pages.{module_name}")
        return module
    except ImportError:
        try:
            # Fallback: try to import directly
            module = importlib.import_module(module_name)
            return module
        except ImportError as e:
            st.error(f"Failed to load page module '{module_name}': {e}")
            return None


def render_sidebar():
    """Render the navigation sidebar"""
    st.sidebar.title("🚨 Incident Management")
    st.sidebar.markdown("Navigate between different views")
    st.sidebar.markdown("---")
    
    # Page selection
    selected_page = st.sidebar.selectbox(
        "Select Page:",
        options=list(PAGE_REGISTRY.keys()),
        index=0,
        key="page_selector"
    )
    
    st.sidebar.markdown("---")
    
    # App info
    st.sidebar.subheader("📋 App Information")
    st.sidebar.info(
        "**Multi-Page Dashboard**\n\n"
        "• **Dashboard**: Key metrics and incident analytics\n"
        "• **Image Comparison**: Side-by-side image comparison tool\n"
        "• **Analytics**: Advanced performance analytics"
    )
    
    st.sidebar.markdown("---")
    st.sidebar.caption(f"🕒 Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return selected_page


def render_page_header(page_name):
    """Render a styled page header"""
    st.markdown(f"""
    <div class="page-header">
        <h2 style="margin: 0; color: white;">{page_name}</h2>
        <p style="margin: 0; color: #f0f0f0; font-size: 0.9rem;">Incident Management System</p>
    </div>
    """, unsafe_allow_html=True)


def main():
    """Main application function with dynamic page loading"""
    
    # Render sidebar and get selected page
    selected_page = render_sidebar()
    
    # Get the module name for the selected page
    module_name = PAGE_REGISTRY.get(selected_page)
    
    if not module_name:
        st.error(f"Page '{selected_page}' not found in registry")
        return
    
    # Load the page module
    page_module = load_page_module(module_name)
    
    if page_module is None:
        st.error(f"Failed to load page: {selected_page}")
        return
    
    # Render page header
    render_page_header(selected_page)
    
    # Check if the module has a render function
    if hasattr(page_module, 'render'):
        try:
            # Call the page's render function
            page_module.render()
        except Exception as e:
            st.error(f"Error rendering page '{selected_page}': {e}")
            st.exception(e)
    else:
        st.error(f"Page module '{module_name}' does not have a 'render' function")


if __name__ == "__main__":
    main()
