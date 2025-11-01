#!/bin/bash
# Quick deployment script for Pi Assistant updates

set -e

echo "🚀 Deploying Pi Assistant updates..."

# SSH connection details (update as needed)
PI_HOST="${PI_HOST:-voice-assistant}"
PI_USER="${PI_USER:-rami}"
PI_PROJECT_DIR="/home/rami/workspace/speak-dutch-to-me"

echo "📡 Connecting to $PI_USER@$PI_HOST..."

# Deploy and restart service
ssh -t "$PI_USER@$PI_HOST" bash << EOF
    set -e
    cd $PI_PROJECT_DIR

    echo "📥 Pulling latest changes..."
    git pull
    
    echo "🔄 Restarting assistant service..."
    sudo systemctl restart pi-assistant
    
    echo "⏳ Waiting for service to start..."
    sleep 3
    
    echo "📊 Service status:"
    sudo systemctl status pi-assistant --no-pager -l | head -20
    
    echo ""
    echo "📝 Recent logs:"
    sudo journalctl -u pi-assistant -n 30 --no-pager
    
    echo ""
    echo "✅ Deployment complete!"
EOF

echo ""
echo "🎉 Done! Check the logs above for any errors."
