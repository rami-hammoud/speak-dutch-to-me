#!/bin/bash
# Install system dependencies for Pi Assistant

echo "=========================================="
echo "📦 Installing System Dependencies"
echo "=========================================="
echo ""

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install ffmpeg for audio conversion
echo ""
echo "Installing ffmpeg for audio conversion..."
sudo apt-get install -y ffmpeg

# Verify installation
echo ""
echo "Verifying installations..."
if command -v ffmpeg &> /dev/null; then
    echo "✅ ffmpeg installed: $(ffmpeg -version | head -n1)"
else
    echo "❌ ffmpeg installation failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All system dependencies installed!"
echo "=========================================="
