#!/bin/bash
# Update Pi Assistant systemd service to use virtual environment

echo "Updating Pi Assistant service to use virtual environment..."

# Detect the current user
CURRENT_USER=$(whoami)
PROJECT_DIR=$(pwd)

# Create new service file with correct user and paths
sudo tee /etc/systemd/system/pi-assistant.service > /dev/null <<EOF
[Unit]
Description=Pi Assistant - Dutch Learning AI
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$PROJECT_DIR/pi-assistant
# Use virtual environment Python
ExecStart=$PROJECT_DIR/pi-assistant/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and restart service
sudo systemctl enable pi-assistant
sudo systemctl restart pi-assistant

echo "✅ Service updated and restarted!"
echo ""
echo "Check status with: sudo systemctl status pi-assistant"