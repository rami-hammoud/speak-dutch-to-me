#!/bin/bash
# Deploy Voice Command System to Raspberry Pi
# Run this script ON YOUR PI after pulling the latest code

set -e

echo "=========================================="
echo "🚀 Deploying Voice Command System"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project directory
cd ~/workspace/speak-dutch-to-me

echo -e "${BLUE}Step 1: Pulling latest code from GitHub...${NC}"
git pull origin main

echo ""
echo -e "${BLUE}Step 2: Installing Python dependencies...${NC}"
cd pi-assistant

# Install Google Calendar dependencies
echo "Installing Google Calendar API packages..."
pip3 install --user google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# Install any other new dependencies
echo "Installing other dependencies..."
pip3 install --user -r requirements.txt || echo "Some packages may already be installed"

echo ""
echo -e "${BLUE}Step 3: Checking services...${NC}"

# Check if assistant is running
if systemctl is-active --quiet pi-assistant; then
    echo "Pi Assistant service is running"
    echo "Restarting service..."
    sudo systemctl restart pi-assistant
else
    echo "Pi Assistant service is not running"
    echo "Starting service..."
    sudo systemctl start pi-assistant
fi

echo ""
echo -e "${BLUE}Step 4: Checking Ollama...${NC}"
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama service is running"
else
    echo "⚠️  Ollama service is not running"
    echo "Starting Ollama..."
    sudo systemctl start ollama
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "🌐 Access Points:"
echo "   Main Dashboard:  http://$(hostname -I | awk '{print $1}'):8080"
echo "   Voice Chat:      http://$(hostname -I | awk '{print $1}'):8080/voice-chat"
echo "   Dutch Learning:  http://$(hostname -I | awk '{print $1}'):8080/dutch-learning"
echo ""
echo "📝 Next Steps:"
echo "   1. Open Voice Chat in your browser"
echo "   2. Grant microphone permissions"
echo "   3. Click the mic and speak!"
echo ""
echo "📚 Optional: Setup Google Calendar"
echo "   Follow: GOOGLE_CALENDAR_SETUP.md"
echo ""
echo "🔍 Monitor logs:"
echo "   sudo journalctl -u pi-assistant -f"
echo ""
echo "🎤 Test voice commands:"
echo "   - 'Find me a wireless keyboard'"
echo "   - 'How do you say hello in Dutch'"
echo "   - 'What's on my calendar today' (after Google setup)"
echo ""
