#!/usr/bin/env python3
"""
Base64 to Video Converter
Converts base64 encoded video data back to a video file
"""

import base64
import sys
import os
from pathlib import Path

def base64_to_video(base64_file_path, output_path=None):
    """
    Convert base64 encoded video data to a video file
    
    Args:
        base64_file_path (str): Path to the base64.txt file
        output_path (str): Output video file path (optional)
    """
    
    # Read the base64 data
    try:
        with open(base64_file_path, 'r') as f:
            base64_data = f.read().strip()
    except FileNotFoundError:
        print(f"Error: File '{base64_file_path}' not found")
        return False
    except Exception as e:
        print(f"Error reading file: {e}")
        return False
    
    # Determine output path
    if output_path is None:
        # Use same name as input but with .mp4 extension
        input_path = Path(base64_file_path)
        output_path = input_path.with_suffix('.mp4')
    
    # Decode base64 to binary
    try:
        video_data = base64.b64decode(base64_data)
    except Exception as e:
        print(f"Error decoding base64 data: {e}")
        return False
    
    # Write to video file
    try:
        with open(output_path, 'wb') as f:
            f.write(video_data)
        print(f"✅ Video saved successfully: {output_path}")
        return True
    except Exception as e:
        print(f"Error writing video file: {e}")
        return False

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python base64_to_video.py <base64_file> [output_file]")
        print("Example: python base64_to_video.py base64.txt my_video.webp")
        return
    
    base64_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = base64_to_video(base64_file, output_file)
    if success:
        print("🎉 Conversion completed successfully!")
    else:
        print("❌ Conversion failed!")

if __name__ == "__main__":
    main() 