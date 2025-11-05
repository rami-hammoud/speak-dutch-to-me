#!/bin/bash
# One-command fix for voice recognition on Pi

set -e

echo "=========================================="
echo "🔧 Applying Voice Recognition Fix"
echo "=========================================="
echo ""

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Step 1: Pulling latest code..."
git pull origin main

echo ""
echo "Step 2: Installing system dependencies..."
./install_system_deps.sh

echo ""
echo "Step 3: Restarting service..."
sudo systemctl restart pi-assistant

echo ""
echo "Step 4: Checking service status..."
sleep 2
sudo systemctl status pi-assistant --no-pager -l

echo ""
echo "=========================================="
echo "✅ Fix Applied Successfully!"
echo "=========================================="
echo ""
echo "🎤 Test it now:"
echo "   1. Open: https://$(hostname -I | awk '{print $1}'):8080/voice-chat"
echo "   2. Click 'Advanced' → 'Proceed' (bypass cert warning)"
echo "   3. Click microphone and say: 'What time is it?'"
echo ""
echo "📊 View logs:"
echo "   sudo journalctl -u pi-assistant -f"
echo ""
