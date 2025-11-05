#!/bin/bash

# Base64 to Video Converter Script
# Usage: ./convert_base64.sh base64.txt [output.webp]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <base64_file> [output_file]"
    echo "Example: $0 base64.txt my_video.webp"
    exit 1
fi

BASE64_FILE="$1"
OUTPUT_FILE="${2:-${BASE64_FILE%.txt}.webp}"

if [ ! -f "$BASE64_FILE" ]; then
    echo "Error: File '$BASE64_FILE' not found"
    exit 1
fi

echo "Converting $BASE64_FILE to $OUTPUT_FILE..."

# Decode base64 and save as video
base64 -d "$BASE64_FILE" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Video saved successfully: $OUTPUT_FILE"
    echo "📁 File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
else
    echo "❌ Conversion failed!"
    exit 1
fi 