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

# Check if we have a virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install Google Calendar dependencies
echo "Installing Google Calendar API packages..."
pip install --upgrade pip
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# Install any other new dependencies
echo "Installing other dependencies..."
pip install -r requirements.txt || echo "Some packages may already be installed"

# Deactivate venv (systemd service will use it)
deactivate

echo ""
echo -e "${BLUE}Step 3: Updating systemd service...${NC}"
cd ..
./update_service.sh

echo ""
echo -e "${BLUE}Step 4: Checking services...${NC}"
cd pi-assistant

# Service is already restarted by update_service.sh
sleep 2
if systemctl is-active --quiet pi-assistant; then
    echo "✅ Pi Assistant service is running"
else
    echo "⚠️  Pi Assistant service failed to start"
    echo "Check logs: sudo journalctl -u pi-assistant -n 50"
fi

echo ""
echo -e "${BLUE}Step 5: Checking Ollama...${NC}"
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
