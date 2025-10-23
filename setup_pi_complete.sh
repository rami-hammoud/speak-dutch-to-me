#!/usr/bin/env bash
# Complete Raspberry Pi Setup for Dutch Learning AI Assistant with MCP
# Supports: Voice (ReSpeaker), Camera (AI HAT+), Virtual Camera, MCP Servers
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[Setup]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

# Check if running on Pi
if [[ ! -f /proc/cpuinfo ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    warn "Not running on Raspberry Pi. Some features may not work."
    read -p "Continue anyway? [y/N]: " cont
    [[ ! "${cont:-N}" =~ ^[Yy]$ ]] && exit 1
fi

log "=================================="
log "  Dutch Learning AI Assistant"
log "  Complete Raspberry Pi Setup"
log "=================================="
echo ""

# 1. System Update
log "Step 1/10: Updating system packages..."
sudo apt update
sudo apt upgrade -y
success "System updated"

# 2. Install base dependencies
log "Step 2/10: Installing base dependencies..."
sudo apt install -y \
    python3-full \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    build-essential \
    cmake \
    pkg-config \
    libasound2-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    ffmpeg \
    v4l-utils \
    i2c-tools
success "Base dependencies installed"

# 3. Install Raspberry Pi specific packages
log "Step 3/10: Installing Raspberry Pi hardware support..."
sudo apt install -y \
    raspberrypi-kernel-headers \
    libcamera-apps \
    libcamera-dev \
    python3-libcamera \
    python3-picamera2 \
    python3-opencv \
    python3-pyaudio
success "Pi hardware support installed"

# 4. Setup virtual camera (v4l2loopback)
log "Step 4/10: Setting up virtual camera for Zoom/Meet..."
sudo apt install -y v4l2loopback-dkms v4l2loopback-utils
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
sudo mkdir -p /etc/modprobe.d
echo "options v4l2loopback devices=1 video_nr=10 card_label=\"PiAssistantCam\" exclusive_caps=1" | \
    sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam" exclusive_caps=1 || \
    warn "v4l2loopback failed to load, will retry after reboot"
success "Virtual camera configured"

# 5. Install Ollama (for local LLM)
log "Step 5/10: Installing Ollama..."
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable ollama
    sudo systemctl start ollama
    sleep 5
    # Pull default model
    ollama pull llama3.2:3b
    success "Ollama installed and llama3.2:3b downloaded"
else
    success "Ollama already installed"
fi

# 6. Setup Python environment
log "Step 6/10: Setting up Python environment..."
cd ~/workspace/speak-dutch-to-me/pi-assistant
if [[ ! -d venv ]]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
    
    # Install core dependencies
    pip install \
        fastapi \
        uvicorn[standard] \
        websockets \
        aiohttp \
        jinja2 \
        python-multipart \
        python-dotenv \
        pydantic \
        pydantic-settings
    
    # Install MCP and agent dependencies
    pip install \
        anthropic \
        openai \
        httpx \
        mcp \
        langchain \
        langchain-community
    
    # Install audio/video (skip if system packages used)
    pip install \
        SpeechRecognition \
        pyttsx3 \
        numpy
    
    # Install utilities
    pip install \
        psutil \
        redis \
        sqlalchemy \
        alembic
    
    deactivate
    success "Python environment created and packages installed"
else
    success "Python environment already exists"
fi

# 7. Setup MCP Server structure
log "Step 7/10: Setting up MCP server modules..."
mkdir -p ~/workspace/speak-dutch-to-me/pi-assistant/mcp/{
modules,tools,agents,config,data}

# Create MCP module structure
cat > ~/workspace/speak-dutch-to-me/pi-assistant/mcp/modules/__init__.py << 'EOF'
"""MCP Server Modules"""
from .personal_assistant import PersonalAssistantModule
from .ecommerce import ECommerceModule
from .smart_home import SmartHomeModule
from .knowledge_base import KnowledgeBaseModule
from .dutch_learning import DutchLearningModule

__all__ = [
    'PersonalAssistantModule',
    'ECommerceModule',
    'SmartHomeModule',
    'KnowledgeBaseModule',
    'DutchLearningModule'
]
EOF

success "MCP server structure created"

# 8. Configure audio (PulseAudio + ALSA)
log "Step 8/10: Configuring audio system..."
sudo apt install -y pulseaudio pavucontrol alsa-utils
systemctl --user enable pulseaudio.service || true
systemctl --user start pulseaudio.service || true

# Create ALSA config
cat > ~/.asoundrc << 'EOF'
# ALSA configuration for ReSpeaker and Pi audio
pcm.!default {
    type asym
    playback.pcm "plughw:0,0"
    capture.pcm "plughw:0,0"
}

ctl.!default {
    type hw
    card 0
}
EOF

success "Audio system configured"

# 9. Create systemd services
log "Step 9/10: Creating systemd services..."

# Main assistant service
sudo tee /etc/systemd/system/pi-assistant.service >/dev/null <<EOF
[Unit]
Description=Dutch Learning AI Assistant
After=network.target ollama.service
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/workspace/speak-dutch-to-me/pi-assistant
Environment="PATH=$HOME/workspace/speak-dutch-to-me/pi-assistant/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$HOME/workspace/speak-dutch-to-me/pi-assistant/venv/bin/uvicorn main:assistant.app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Virtual camera service
sudo tee /etc/systemd/system/virtual-camera.service >/dev/null <<EOF
[Unit]
Description=Virtual Camera Stream for Zoom
After=network.target systemd-modules-load.service
Wants=network.target

[Service]
Type=simple
User=$USER
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/stream-to-virtual-cam.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create virtual camera streaming script
sudo tee /usr/local/bin/stream-to-virtual-cam.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
VFLIP="--vflip"
HFLIP="--hflip"
WIDTH=640
HEIGHT=480
FPS=30
OUTPUT_DEV=/dev/video10
sleep 5
exec rpicam-vid -t 0 --width $WIDTH --height $HEIGHT --framerate $FPS $VFLIP $HFLIP -n --codec yuv420 -o - | \
ffmpeg -loglevel error -f rawvideo -pix_fmt yuv420p -s ${WIDTH}x${HEIGHT} -r $FPS -i - -f v4l2 -pix_fmt yuv420p $OUTPUT_DEV
EOF
sudo chmod +x /usr/local/bin/stream-to-virtual-cam.sh

sudo systemctl daemon-reload
success "Systemd services created"

# 10. Create configuration files
log "Step 10/10: Creating configuration files..."

# Create .env template
cat > ~/workspace/speak-dutch-to-me/pi-assistant/.env.example << 'EOF'
# Server Settings
HOST=0.0.0.0
PORT=8080
DEBUG=true

# AI Providers
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4
ANTHROPIC_API_KEY=
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b

# Camera Settings
CAMERA_ENABLED=true
CAMERA_VFLIP=true
CAMERA_HFLIP=true
FORCE_USB_CAMERA=false
USE_AI_HAT_CAMERA=true

# Audio Settings
AUDIO_INPUT_DEVICE=
AUDIO_OUTPUT_DEVICE=

# MCP Server Settings
MCP_ENABLED=true
MCP_PORT=8081

# Personal Assistant
GOOGLE_CALENDAR_ENABLED=false
GOOGLE_CALENDAR_CREDENTIALS=
TODOIST_API_KEY=
NOTION_API_KEY=

# E-Commerce
AMAZON_API_KEY=
EBAY_API_KEY=
STRIPE_API_KEY=

# Smart Home
HOME_ASSISTANT_URL=
HOME_ASSISTANT_TOKEN=

# Knowledge Base
BRAVE_SEARCH_API_KEY=
WIKIPEDIA_ENABLED=true

# Dutch Learning
DUTCH_VOCABULARY_DB=./data/dutch_vocab.db
PROGRESS_TRACKING=true
EOF

# Copy to actual .env if it doesn't exist
if [[ ! -f ~/workspace/speak-dutch-to-me/pi-assistant/.env ]]; then
    cp ~/workspace/speak-dutch-to-me/pi-assistant/.env.example \
       ~/workspace/speak-dutch-to-me/pi-assistant/.env
fi

success "Configuration files created"

# Summary
echo ""
log "=================================="
log "  Setup Complete!"
log "=================================="
echo ""
success "All components installed successfully"
echo ""
log "Next steps:"
echo "  1. Edit configuration: nano ~/workspace/speak-dutch-to-me/pi-assistant/.env"
echo "  2. Add API keys (OpenAI, Anthropic, etc.)"
echo "  3. Enable services:"
echo "     sudo systemctl enable pi-assistant.service"
echo "     sudo systemctl enable virtual-camera.service"
echo "  4. Reboot to activate all changes:"
echo "     sudo reboot"
echo ""
log "After reboot:"
echo "  - Pi Assistant: http://$(hostname -I | awk '{print $1}'):8080"
echo "  - Virtual camera: /dev/video10 (for Zoom/Meet)"
echo "  - Ollama API: http://localhost:11434"
echo ""
log "Service management:"
echo "  sudo systemctl status pi-assistant"
echo "  sudo systemctl status virtual-camera"
echo "  sudo journalctl -u pi-assistant -f"
echo ""
log "For detailed setup of individual components, see:"
echo "  - ./setup_respeaker_xvf3800.sh (for microphone)"
echo "  - ./fix_ai_hat_camera.sh (if camera issues)"
echo "  - ./manage_virtual_camera.sh (virtual camera control)"
echo ""
success "Setup script complete!"
