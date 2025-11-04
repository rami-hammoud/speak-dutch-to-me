#!/bin/bash
# Update Pi Assistant systemd service to use virtual environment

echo "Updating Pi Assistant service to use virtual environment..."

# Create new service file
sudo tee /etc/systemd/system/pi-assistant.service > /dev/null <<EOF
[Unit]
Description=Pi Assistant - Dutch Learning AI
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/workspace/speak-dutch-to-me/pi-assistant
# Use virtual environment Python
ExecStart=/home/pi/workspace/speak-dutch-to-me/pi-assistant/venv/bin/python main.py
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
