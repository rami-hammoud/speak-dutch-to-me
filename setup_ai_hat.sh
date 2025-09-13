#!/bin/bash

# AI HAT+ Quick Setup Script for Raspberry Pi 5
# This is a companion script for the Python setup

set -e  # Exit on any error

echo "🤖 AI HAT+ Quick Setup for Raspberry Pi 5"
echo "=========================================="
echo "Companion to the Python setup script"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Please don't run this script as root (no sudo)"
   exit 1
fi

# Check if on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Quick system update
echo "📦 Quick system update..."
sudo apt update

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt install -y i2c-tools python3-pip wget curl

# Enable I2C quickly
echo "🔧 Enabling I2C..."
sudo raspi-config nonint do_i2c 0

# Check for existing setup
echo "🔍 Checking current setup..."

# Check I2C
if [ -e /dev/i2c-1 ]; then
    echo "   ✅ I2C enabled"
    echo "   I2C devices:"
    sudo i2cdetect -y 1 2>/dev/null || echo "   No devices found"
else
    echo "   ❌ I2C not working - may need reboot"
fi

# Check for Hailo
if lspci 2>/dev/null | grep -i hailo; then
    echo "   ✅ Hailo device detected"
else
    echo "   ⚠️  Hailo device not detected"
fi

# Check for HailoRT
if command -v hailortcli >/dev/null 2>&1; then
    echo "   ✅ HailoRT installed"
    hailortcli scan 2>/dev/null || echo "   HailoRT scan failed"
else
    echo "   ❌ HailoRT not installed"
fi

echo ""
echo "🚀 Quick setup complete!"
echo ""
echo "For full setup, run:"
echo "   python3 test_ai_hat.py"
echo ""
echo "If you need to reboot:"
echo "   sudo reboot"
