#!/bin/bash
# Setup HTTPS for Pi Assistant with self-signed certificate

set -e

echo "=========================================="
echo "🔒 Setting up HTTPS for Pi Assistant"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get hostname
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "${BLUE}Step 1: Creating SSL certificate directory...${NC}"
cd ~/workspace/speak-dutch-to-me/pi-assistant
mkdir -p ssl

echo ""
echo -e "${BLUE}Step 2: Generating self-signed SSL certificate...${NC}"
echo "This certificate will be valid for:"
echo "  - localhost"
echo "  - $HOSTNAME"
echo "  - $HOSTNAME.local"
echo "  - $IP_ADDRESS"
echo ""

# Generate private key and certificate
openssl req -x509 -newkey rsa:4096 -nodes \
  -out ssl/cert.pem \
  -keyout ssl/key.pem \
  -days 365 \
  -subj "/C=US/ST=State/L=City/O=PiAssistant/CN=$HOSTNAME" \
  -addext "subjectAltName=DNS:$HOSTNAME,DNS:$HOSTNAME.local,DNS:localhost,IP:$IP_ADDRESS"

echo ""
echo -e "${GREEN}✅ Certificate generated!${NC}"
echo "  Certificate: ~/workspace/speak-dutch-to-me/pi-assistant/ssl/cert.pem"
echo "  Private Key: ~/workspace/speak-dutch-to-me/pi-assistant/ssl/key.pem"

echo ""
echo -e "${BLUE}Step 3: Installing Python HTTPS dependencies...${NC}"
source venv/bin/activate
pip install --upgrade uvicorn[standard]
deactivate

echo ""
echo -e "${BLUE}Step 4: Updating systemd service for HTTPS...${NC}"

# Update service to use HTTPS
sudo tee /etc/systemd/system/pi-assistant.service > /dev/null <<EOF
[Unit]
Description=Pi Assistant - Dutch Learning AI (HTTPS)
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
# Use HTTPS with SSL certificate
ExecStart=$(pwd)/venv/bin/uvicorn main:assistant.app --host 0.0.0.0 --port 8080 --ssl-keyfile ssl/key.pem --ssl-certfile ssl/cert.pem
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart pi-assistant

echo ""
echo -e "${GREEN}=========================================="
echo "✅ HTTPS Setup Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}📋 IMPORTANT: How to Access${NC}"
echo ""
echo "1. Open in your browser:"
echo -e "   ${GREEN}https://$IP_ADDRESS:8080/voice-chat${NC}"
echo "   or"
echo -e "   ${GREEN}https://$HOSTNAME:8080/voice-chat${NC}"
echo ""
echo "2. You'll see a security warning (this is normal for self-signed certs)"
echo "   Click: 'Advanced' → 'Proceed to $HOSTNAME (unsafe)'"
echo ""
echo "3. Grant microphone permission when prompted"
echo ""
echo -e "${YELLOW}📱 On macOS:${NC}"
echo "   - Safari: Will show warning, click 'Show Details' → 'visit this website'"
echo "   - Chrome: Click 'Advanced' → 'Proceed to $HOSTNAME (unsafe)'"
echo "   - Firefox: Click 'Advanced' → 'Accept the Risk and Continue'"
echo ""
echo -e "${YELLOW}🔍 Verify Service:${NC}"
echo "   sudo systemctl status pi-assistant"
echo ""
echo -e "${YELLOW}📊 View Logs:${NC}"
echo "   sudo journalctl -u pi-assistant -f"
echo ""
echo -e "${GREEN}🎤 Now you can use the microphone!${NC}"
echo ""
