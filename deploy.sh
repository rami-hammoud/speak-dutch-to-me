#!/bin/bash
# ============================================================================
# Pi Assistant - Master Deployment Script
# ============================================================================
# This is the ONLY script you need to deploy Pi Assistant on a Raspberry Pi
# 
# Works for:
#   - Fresh installation on a new Pi
#   - Updating existing installation
#   - Fixing issues (re-runs all setup steps)
#
# Usage:
#   ./deploy.sh                    # Full interactive deployment
#   ./deploy.sh --quick            # Skip system updates (faster for updates)
#   ./deploy.sh --https            # Include HTTPS setup
#   ./deploy.sh --quick --https    # Quick update with HTTPS
# ============================================================================

set -e

# ============================================================================
# Configuration & Colors
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Parse command line arguments
QUICK_MODE=false
SETUP_HTTPS=false
SKIP_SYSTEM_UPDATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick|-q)
            QUICK_MODE=true
            SKIP_SYSTEM_UPDATE=true
            shift
            ;;
        --https)
            SETUP_HTTPS=true
            shift
            ;;
        --help|-h)
            echo "Pi Assistant Deployment Script"
            echo ""
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick, -q      Skip system updates (faster for updates)"
            echo "  --https          Setup HTTPS with self-signed certificate"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./deploy.sh                    # Full deployment"
            echo "  ./deploy.sh --quick            # Quick update"
            echo "  ./deploy.sh --https            # Full deployment with HTTPS"
            echo "  ./deploy.sh --quick --https    # Quick update with HTTPS"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run './deploy.sh --help' for usage information"
            exit 1
            ;;
    esac
done

# Get system info
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
PROJECT_DIR="$HOME/workspace/speak-dutch-to-me"
PI_ASSISTANT_DIR="$PROJECT_DIR/pi-assistant"

# ============================================================================
# Helper Functions
# ============================================================================

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step() { 
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$*${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# ============================================================================
# Banner
# ============================================================================

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              🤖 Pi Assistant Deployment 🤖                   ║
║                                                               ║
║          AI-Powered Voice Assistant for Raspberry Pi          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log "Hostname: $HOSTNAME"
log "IP Address: $IP_ADDRESS"
log "Project Directory: $PROJECT_DIR"
if [ "$QUICK_MODE" = true ]; then
    warn "Quick Mode: Skipping system updates"
fi
if [ "$SETUP_HTTPS" = true ]; then
    log "HTTPS Mode: Will setup SSL certificates"
fi
echo ""

# ============================================================================
# STEP 1: System Updates (Optional)
# ============================================================================

if [ "$SKIP_SYSTEM_UPDATE" = false ]; then
    step "STEP 1/8: System Update"
    
    log "Updating package lists..."
    sudo apt-get update
    
    log "Upgrading packages (this may take a while)..."
    sudo apt-get upgrade -y
    
    success "System updated"
else
    step "STEP 1/8: System Update (SKIPPED)"
    warn "Skipping system updates in quick mode"
fi

# ============================================================================
# STEP 2: Install System Dependencies
# ============================================================================

step "STEP 2/8: Installing System Dependencies"

log "Installing audio processing tools..."
sudo apt-get install -y ffmpeg flac

log "Installing Python and build tools..."
sudo apt-get install -y \
    python3-full \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    curl \
    wget \
    build-essential

log "Installing audio libraries..."
sudo apt-get install -y \
    libasound2-dev \
    portaudio19-dev \
    libportaudio2 \
    pulseaudio \
    alsa-utils

log "Verifying installations..."
if command -v ffmpeg &> /dev/null; then
    success "ffmpeg installed: $(ffmpeg -version 2>&1 | head -n1)"
else
    error "ffmpeg installation failed"
fi

if command -v flac &> /dev/null; then
    success "FLAC installed: $(flac --version 2>&1 | head -n1)"
else
    error "FLAC installation failed"
fi

success "System dependencies installed"

# ============================================================================
# STEP 3: Setup Project Directory
# ============================================================================

step "STEP 3/8: Setting Up Project"

if [ ! -d "$PROJECT_DIR" ]; then
    log "Cloning repository..."
    mkdir -p "$HOME/workspace"
    cd "$HOME/workspace"
    git clone https://github.com/rami-hammoud/speak-dutch-to-me.git
    cd speak-dutch-to-me
    success "Repository cloned"
else
    log "Project directory exists, pulling latest code..."
    cd "$PROJECT_DIR"
    git pull origin main || warn "Could not pull latest code (may have local changes)"
    success "Code updated"
fi

# ============================================================================
# STEP 4: Setup Python Virtual Environment
# ============================================================================

step "STEP 4/8: Setting Up Python Environment"

cd "$PI_ASSISTANT_DIR"

if [ ! -d "venv" ]; then
    log "Creating virtual environment..."
    python3 -m venv venv
    success "Virtual environment created"
else
    log "Virtual environment already exists"
fi

log "Activating virtual environment..."
source venv/bin/activate

log "Upgrading pip..."
pip install --upgrade pip

log "Installing Python dependencies..."
pip install -r requirements.txt

# Install additional packages that may not be in requirements.txt
log "Installing Google Calendar dependencies..."
pip install --upgrade \
    google-auth \
    google-auth-oauthlib \
    google-auth-httplib2 \
    google-api-python-client

log "Installing voice recognition dependencies..."
pip install --upgrade \
    SpeechRecognition \
    uvicorn[standard]

deactivate
success "Python environment configured"

# ============================================================================
# STEP 5: Create Required Directories
# ============================================================================

step "STEP 5/8: Creating Directory Structure"

cd "$PI_ASSISTANT_DIR"

mkdir -p logs
mkdir -p data
mkdir -p ssl
mkdir -p credentials

log "Setting permissions..."
chmod 755 logs data ssl credentials

success "Directory structure created"

# ============================================================================
# STEP 6: Setup HTTPS (Optional)
# ============================================================================

if [ "$SETUP_HTTPS" = true ]; then
    step "STEP 6/8: Setting Up HTTPS"
    
    cd "$PI_ASSISTANT_DIR"
    
    if [ -f "ssl/cert.pem" ] && [ -f "ssl/key.pem" ]; then
        warn "SSL certificates already exist"
        read -p "Regenerate certificates? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Keeping existing certificates"
        else
            log "Generating new SSL certificates..."
            openssl req -x509 -newkey rsa:4096 -nodes \
                -out ssl/cert.pem \
                -keyout ssl/key.pem \
                -days 365 \
                -subj "/C=US/ST=State/L=City/O=PiAssistant/CN=$HOSTNAME" \
                -addext "subjectAltName=DNS:$HOSTNAME,DNS:$HOSTNAME.local,DNS:localhost,IP:$IP_ADDRESS"
            success "SSL certificates generated"
        fi
    else
        log "Generating SSL certificates..."
        openssl req -x509 -newkey rsa:4096 -nodes \
            -out ssl/cert.pem \
            -keyout ssl/key.pem \
            -days 365 \
            -subj "/C=US/ST=State/L=City/O=PiAssistant/CN=$HOSTNAME" \
            -addext "subjectAltName=DNS:$HOSTNAME,DNS:$HOSTNAME.local,DNS:localhost,IP:$IP_ADDRESS"
        success "SSL certificates generated"
    fi
else
    step "STEP 6/8: HTTPS Setup (SKIPPED)"
    warn "HTTPS not configured. Run with --https to enable secure connections"
    warn "Note: Browser microphone access requires HTTPS!"
fi

# ============================================================================
# STEP 7: Configure Systemd Service
# ============================================================================

step "STEP 7/8: Configuring Systemd Service"

cd "$PROJECT_DIR"

# Determine ExecStart command based on HTTPS mode
if [ "$SETUP_HTTPS" = true ] && [ -f "$PI_ASSISTANT_DIR/ssl/cert.pem" ]; then
    EXEC_START="$PI_ASSISTANT_DIR/venv/bin/uvicorn main:assistant.app --host 0.0.0.0 --port 8080 --ssl-keyfile ssl/key.pem --ssl-certfile ssl/cert.pem"
    SERVICE_DESC="Pi Assistant - Dutch Learning AI (HTTPS)"
else
    EXEC_START="$PI_ASSISTANT_DIR/venv/bin/python main.py"
    SERVICE_DESC="Pi Assistant - Dutch Learning AI"
fi

log "Creating systemd service file..."
sudo tee /etc/systemd/system/pi-assistant.service > /dev/null <<EOF
[Unit]
Description=$SERVICE_DESC
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$PI_ASSISTANT_DIR
ExecStart=$EXEC_START
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

log "Reloading systemd daemon..."
sudo systemctl daemon-reload

log "Enabling service to start on boot..."
sudo systemctl enable pi-assistant

success "Systemd service configured"

# ============================================================================
# STEP 8: Start Services
# ============================================================================

step "STEP 8/8: Starting Services"

# Check if Ollama is installed and running
if command -v ollama &> /dev/null; then
    if systemctl is-active --quiet ollama; then
        success "Ollama service is running"
    else
        log "Starting Ollama service..."
        sudo systemctl start ollama || warn "Could not start Ollama"
    fi
else
    warn "Ollama not installed. Install it with: curl https://ollama.ai/install.sh | sh"
fi

log "Starting Pi Assistant service..."
sudo systemctl restart pi-assistant

sleep 3

if systemctl is-active --quiet pi-assistant; then
    success "Pi Assistant service is running"
else
    error "Pi Assistant service failed to start. Check logs: sudo journalctl -u pi-assistant -n 50"
fi

# ============================================================================
# Deployment Complete
# ============================================================================

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""

if [ "$SETUP_HTTPS" = true ]; then
    PROTOCOL="https"
    PORT_NOTE=" (HTTPS)"
else
    PROTOCOL="http"
    PORT_NOTE=" (HTTP - microphone may not work)"
fi

echo -e "${CYAN}🌐 Access Points:${NC}"
echo "   Voice Chat:      $PROTOCOL://$IP_ADDRESS:8080/voice-chat$PORT_NOTE"
echo "   Main Dashboard:  $PROTOCOL://$IP_ADDRESS:8080"
echo "   Dutch Learning:  $PROTOCOL://$IP_ADDRESS:8080/dutch-learning"
echo ""

if [ "$SETUP_HTTPS" = true ]; then
    echo -e "${YELLOW}🔒 HTTPS Certificate Warning:${NC}"
    echo "   Your browser will show a security warning (this is normal)"
    echo "   Click 'Advanced' → 'Proceed to $IP_ADDRESS (unsafe)'"
    echo ""
fi

echo -e "${CYAN}🔍 Useful Commands:${NC}"
echo "   Check status:    sudo systemctl status pi-assistant"
echo "   View logs:       sudo journalctl -u pi-assistant -f"
echo "   Restart service: sudo systemctl restart pi-assistant"
echo "   Stop service:    sudo systemctl stop pi-assistant"
echo ""

echo -e "${CYAN}🎤 Test Voice Commands:${NC}"
echo "   - 'What time is it?'"
echo "   - 'What's Dutch for hello?'"
echo "   - 'Add milk to my shopping list'"
echo "   - 'Add meeting tomorrow at 3pm'"
echo ""

echo -e "${CYAN}📚 Next Steps:${NC}"
if [ "$SETUP_HTTPS" = false ]; then
    echo "   1. Run './deploy.sh --https' to enable HTTPS for microphone access"
fi
echo "   2. Setup Google Calendar (optional): See GOOGLE_CALENDAR_SETUP.md"
echo "   3. Configure Ollama models: ollama pull llama2"
echo ""

echo -e "${CYAN}🆘 Troubleshooting:${NC}"
echo "   See: FIX_VOICE_RECOGNITION.md"
echo "   See: README_DEPLOY.md"
echo ""

echo -e "${GREEN}🎉 Pi Assistant is ready to use!${NC}"
echo ""

# Show service status
echo -e "${BLUE}Current Service Status:${NC}"
sudo systemctl status pi-assistant --no-pager -l | head -n 15
echo ""
