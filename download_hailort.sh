#!/bin/bash

# HailoRT Download Helper Script
# This script helps you download and install HailoRT for AI HAT+

echo "🚀 HailoRT Download Helper for AI HAT+"
echo "======================================="

# Check if we're on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  This script should be run on Raspberry Pi"
fi

# Check for existing HailoRT files
existing_files=(hailort*.deb)
if [[ -f "${existing_files[0]}" ]]; then
    echo "✅ Found existing HailoRT package: ${existing_files[0]}"
    echo "Proceeding with installation..."
    
    # Install the package
    echo "📦 Installing HailoRT..."
    sudo dpkg -i "${existing_files[0]}"
    
    # Fix dependencies
    echo "🔧 Fixing dependencies..."
    sudo apt-get install -f -y
    
    # Test installation
    echo "🧪 Testing installation..."
    if command -v hailortcli >/dev/null 2>&1; then
        echo "✅ HailoRT CLI installed successfully"
        echo "Testing device scan..."
        hailortcli scan || echo "⚠️  No devices found (normal if HAT+ not connected)"
    else
        echo "❌ HailoRT installation failed"
        exit 1
    fi
    
    echo ""
    echo "🎉 HailoRT installation complete!"
    echo "You can now run: python3 test_ai_hat.py"
    
else
    echo "❌ No HailoRT .deb files found in current directory"
    echo ""
    echo "📥 To download HailoRT manually:"
    echo "1. Open a web browser"
    echo "2. Go to: https://hailo.ai/developer-zone/software-downloads/"
    echo "3. Register/login to Hailo's developer zone"
    echo "4. Download: 'HailoRT Suite for Raspberry Pi 5'"
    echo "5. Transfer the .deb file to this directory"
    echo ""
    echo "📤 Transfer options:"
    echo "   Option A - SCP from another machine:"
    echo "     scp hailort-*.deb rami@$(hostname):$(pwd)/"
    echo ""
    echo "   Option B - Direct download on Pi (if URL available):"
    echo "     wget -O hailort-rpi5.deb 'https://your-download-url-here'"
    echo ""
    echo "After downloading, run this script again!"
fi
