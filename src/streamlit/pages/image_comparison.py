"""
Image Comparison page module for the Incident Management Streamlit app
"""

import streamlit as st
import os
from PIL import Image


def render():
    """Render the image comparison page"""
    
    st.title("🖼️ Image Comparison")
    st.markdown("Compare incident-related images side by side")
    st.markdown("---")
    
    # Image directory path
    image_dir = "/Users/clakkad/Documents/Work/publish/incident-management/data/images"
    
    # Get available images
    if not os.path.exists(image_dir):
        st.error(f"Image directory not found: {image_dir}")
        st.info("Please create the directory and add some images to use the comparison feature.")
        return
        
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

