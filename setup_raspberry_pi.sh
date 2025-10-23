#!/usr/bin/env bash
# Raspberry Pi Setup Script for Dutch Learning AI Assistant
# This script sets up everything needed to run the assistant on a Raspberry Pi
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step() { echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$*${NC}"; echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ASSISTANT_DIR="$SCRIPT_DIR/pi-assistant"
VENV_DIR="$PI_ASSISTANT_DIR/venv"
DATA_DIR="$PI_ASSISTANT_DIR/data"
LOGS_DIR="$PI_ASSISTANT_DIR/logs"

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [[ ! -f /proc/cpuinfo ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        warn "Not running on Raspberry Pi detected."
        warn "Some hardware features (camera, GPIO) may not work."
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && error "Setup cancelled"
    fi
}

# Print welcome banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Dutch Learning AI Assistant - Raspberry Pi Setup       ║
║                                                           ║
║   This will install:                                      ║
║   • Python environment & dependencies                     ║
║   • Ollama (local LLM)                                    ║
║   • Camera & Audio drivers                                ║
║   • Virtual camera for Zoom/Meet                          ║
║   • Database & seed data                                  ║
║   • Systemd services (optional)                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ============================================================================
# STEP 1: System Update
# ============================================================================
update_system() {
    step "STEP 1/9: Updating System Packages"
    log "Updating package lists..."
    sudo apt update
    
    log "Upgrading installed packages (this may take a while)..."
    sudo apt upgrade -y
    
    success "System updated successfully"
}

# ============================================================================
# STEP 2: Install Base Dependencies
# ============================================================================
install_base_dependencies() {
    step "STEP 2/9: Installing Base Dependencies"
    
    log "Installing Python and build tools..."
    sudo apt install -y \
        python3-full \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        curl \
        wget \
        build-essential \
        cmake \
        pkg-config
    
    log "Installing audio libraries..."
    sudo apt install -y \
        libasound2-dev \
        portaudio19-dev \
        libportaudio2 \
        libportaudiocpp0 \
        pulseaudio \
        pavucontrol \
        alsa-utils \
        ffmpeg
    
    log "Installing video/camera libraries..."
    sudo apt install -y \
        v4l-utils \
        libv4l-dev \
        i2c-tools
    
    success "Base dependencies installed"
}

# ============================================================================
# STEP 3: Install Raspberry Pi Hardware Support
# ============================================================================
install_pi_hardware() {
    step "STEP 3/9: Installing Raspberry Pi Hardware Support"
    
    log "Installing camera support..."
    sudo apt install -y \
        raspberrypi-kernel-headers \
        libcamera-apps \
        libcamera-dev \
        python3-libcamera \
        python3-picamera2
    
    log "Installing system Python libraries (better for Python 3.13)..."
    sudo apt install -y \
        python3-opencv \
        python3-pyaudio \
        python3-numpy \
        python3-pil \
        python3-scipy || warn "Some Python libraries not available"
    
    # Enable camera interface
    log "Enabling camera interface..."
    sudo raspi-config nonint do_camera 0 || warn "Camera interface already enabled or not available"
    
    # Enable I2C for audio HATs
    log "Enabling I2C interface..."
    sudo raspi-config nonint do_i2c 0 || warn "I2C interface already enabled or not available"
    
    success "Raspberry Pi hardware support installed"
}

# ============================================================================
# STEP 4: Setup Virtual Camera
# ============================================================================
setup_virtual_camera() {
    step "STEP 4/9: Setting Up Virtual Camera for Zoom/Meet"
    
    log "Installing v4l2loopback..."
    sudo apt install -y v4l2loopback-dkms v4l2loopback-utils
    
    log "Configuring v4l2loopback to load at boot..."
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
    
    sudo mkdir -p /etc/modprobe.d
    echo "options v4l2loopback devices=1 video_nr=10 card_label=\"PiAssistantCam\" exclusive_caps=1" | \
        sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
    
    log "Loading v4l2loopback kernel module..."
    sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam" exclusive_caps=1 || \
        warn "v4l2loopback failed to load, will retry after reboot"
    
    # Create virtual camera streaming script
    log "Creating virtual camera streaming script..."
    sudo tee /usr/local/bin/stream-to-virtual-cam.sh >/dev/null <<'CAMERA_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Configuration
VFLIP="--vflip"
HFLIP="--hflip"
WIDTH=640
HEIGHT=480
FPS=30
OUTPUT_DEV=/dev/video10

# Wait for camera to be ready
sleep 5

# Stream camera to virtual device
exec rpicam-vid -t 0 --width $WIDTH --height $HEIGHT --framerate $FPS $VFLIP $HFLIP -n --codec yuv420 -o - | \
ffmpeg -loglevel error -f rawvideo -pix_fmt yuv420p -s ${WIDTH}x${HEIGHT} -r $FPS -i - -f v4l2 -pix_fmt yuv420p $OUTPUT_DEV
CAMERA_SCRIPT
    
    sudo chmod +x /usr/local/bin/stream-to-virtual-cam.sh
    
    success "Virtual camera configured at /dev/video10"
}

# ============================================================================
# STEP 5: Install Ollama (Local LLM)
# ============================================================================
install_ollama() {
    step "STEP 5/9: Installing Ollama (Local LLM)"
    
    if command -v ollama &>/dev/null; then
        success "Ollama already installed"
        ollama --version
    else
        log "Downloading and installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
        
        log "Enabling Ollama service..."
        sudo systemctl enable ollama
        sudo systemctl start ollama
        
        log "Waiting for Ollama to start..."
        sleep 5
        
        log "Pulling llama3.2:3b model (this will take a while)..."
        ollama pull llama3.2:3b
        
        success "Ollama installed and llama3.2:3b model downloaded"
    fi
    
    # Verify Ollama is running
    if systemctl is-active --quiet ollama; then
        success "Ollama service is running"
    else
        warn "Ollama service is not running. You may need to start it manually."
    fi
}

# ============================================================================
# STEP 6: Setup Python Virtual Environment
# ============================================================================
setup_python_environment() {
    step "STEP 6/9: Setting Up Python Virtual Environment"
    
    cd "$PI_ASSISTANT_DIR"
    
    if [[ -d "$VENV_DIR" ]]; then
        warn "Virtual environment already exists. Removing old environment..."
        rm -rf "$VENV_DIR"
    fi
    
    log "Creating Python virtual environment with system packages..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    
    log "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"
    
    log "Upgrading pip and build tools (Python 3.13 compatible)..."
    pip install --upgrade pip
    pip install --upgrade "setuptools>=70.0.0" "wheel>=0.42.0"
    
    log "Installing core web framework dependencies..."
    pip install fastapi uvicorn[standard] jinja2 python-dotenv websockets || error "Failed to install web framework"
    
    log "Installing HTTP client libraries..."
    pip install httpx aiohttp requests || warn "Some HTTP libraries failed"
    
    log "Installing AI/LLM libraries..."
    pip install anthropic openai || warn "AI libraries failed (optional)"
    
    log "Installing database and utilities..."
    pip install aiosqlite psutil python-multipart || warn "Some utilities failed"
    
    log "Installing audio libraries (using system packages where possible)..."
    pip install SpeechRecognition pyttsx3 || warn "Audio libraries failed - using system packages"
    
    log "Installing remaining dependencies from requirements.txt..."
    if [[ -f requirements.txt ]]; then
        # Try to install remaining packages, but don't fail if some don't work
        pip install -r requirements.txt 2>&1 | tee /tmp/pip-install.log || {
            warn "Some packages from requirements.txt failed to install"
            warn "Check /tmp/pip-install.log for details"
        }
    else
        warn "requirements.txt not found, installed core packages only"
    fi
    
    log "Verifying critical imports..."
    python -c "import fastapi, uvicorn; print('✓ Web framework: OK')" || error "Web framework not working"
    python -c "import cv2, numpy; print('✓ Computer vision: OK')" || warn "OpenCV not available (optional)"
    python -c "import sqlite3; print('✓ Database: OK')" || error "Database not working"
    
    deactivate
    
    success "Python virtual environment configured"
    log "Note: Using system packages for OpenCV, NumPy, and PyAudio (better compatibility)"
}

# ============================================================================
# STEP 7: Configure Audio System
# ============================================================================
configure_audio() {
    step "STEP 7/9: Configuring Audio System"
    
    log "Enabling PulseAudio for user..."
    systemctl --user enable pulseaudio.service || true
    systemctl --user start pulseaudio.service || true
    
    log "Creating ALSA configuration..."
    cat > ~/.asoundrc << 'ALSA_CONFIG'
# ALSA configuration for Raspberry Pi Audio
pcm.!default {
    type asym
    playback.pcm "plughw:0,0"
    capture.pcm "plughw:0,0"
}

ctl.!default {
    type hw
    card 0
}
ALSA_CONFIG
    
    success "Audio system configured"
}

# ============================================================================
# STEP 8: Setup Database and Seed Data
# ============================================================================
setup_database() {
    step "STEP 8/9: Setting Up Database and Seed Data"
    
    cd "$PI_ASSISTANT_DIR"
    
    # Create data directory
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOGS_DIR"
    
    log "Initializing database..."
    source "$VENV_DIR/bin/activate"
    
    # Run seed data loader if it exists
    if [[ -f load_seed_data.py ]]; then
        log "Loading seed vocabulary data..."
        python load_seed_data.py || warn "Seed data loading failed"
    else
        warn "load_seed_data.py not found, skipping seed data"
    fi
    
    deactivate
    
    success "Database and seed data configured"
}

# ============================================================================
# STEP 9: Create Configuration Files
# ============================================================================
create_configuration() {
    step "STEP 9/9: Creating Configuration Files"
    
    cd "$PI_ASSISTANT_DIR"
    
    # Create .env file if it doesn't exist
    if [[ ! -f .env ]]; then
        log "Creating .env configuration file..."
        cat > .env << 'ENV_CONFIG'
# Server Settings
HOST=0.0.0.0
PORT=8080
DEBUG=true

# Directories
DATA_DIR=./data
LOGS_DIR=./logs

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

# Dutch Learning
DUTCH_VOCABULARY_DB=./data/dutch_vocab.db
PROGRESS_TRACKING=true
LIBRE_TRANSLATE_URL=https://libretranslate.com

# Personal Assistant
GOOGLE_CALENDAR_ENABLED=false
TODOIST_API_KEY=
NOTION_API_KEY=

# E-Commerce
AMAZON_API_KEY=
STRIPE_API_KEY=

# Knowledge Base
BRAVE_SEARCH_API_KEY=
WIKIPEDIA_ENABLED=true
ENV_CONFIG
        success ".env file created"
    else
        success ".env file already exists"
    fi
    
    # Make start script executable
    if [[ -f start_assistant.sh ]]; then
        chmod +x start_assistant.sh
        success "start_assistant.sh is executable"
    fi
}

# ============================================================================
# Optional: Create Systemd Services
# ============================================================================
create_systemd_services() {
    step "OPTIONAL: Create Systemd Services"
    
    read -p "Do you want to create systemd services for auto-start? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Skipping systemd service creation"
        return
    fi
    
    log "Creating pi-assistant systemd service..."
    sudo tee /etc/systemd/system/pi-assistant.service >/dev/null <<SERVICE
[Unit]
Description=Dutch Learning AI Assistant
After=network.target ollama.service
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PI_ASSISTANT_DIR
Environment="PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$VENV_DIR/bin/uvicorn main:assistant.app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE
    
    log "Creating virtual-camera systemd service..."
    sudo tee /etc/systemd/system/virtual-camera.service >/dev/null <<VCAM_SERVICE
[Unit]
Description=Virtual Camera Stream for Zoom/Meet
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
VCAM_SERVICE
    
    log "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    success "Systemd services created"
    
    read -p "Do you want to enable services to start on boot? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl enable pi-assistant.service
        sudo systemctl enable virtual-camera.service
        success "Services enabled for auto-start"
    else
        log "Services created but not enabled"
        log "To enable later, run:"
        log "  sudo systemctl enable pi-assistant.service"
        log "  sudo systemctl enable virtual-camera.service"
    fi
}

# ============================================================================
# Print Summary
# ============================================================================
print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║              🎉 SETUP COMPLETE! 🎉                        ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    success "All components installed successfully!"
    echo ""
    
    log "📋 Next Steps:"
    echo ""
    echo "  1. Edit configuration (add API keys):"
    echo "     nano $PI_ASSISTANT_DIR/.env"
    echo ""
    echo "  2. Start the assistant:"
    echo "     cd $PI_ASSISTANT_DIR"
    echo "     ./start_assistant.sh"
    echo ""
    echo "  3. Access the web interface:"
    echo "     http://$(hostname -I | awk '{print $1}'):8080"
    echo ""
    
    log "🎥 Virtual Camera:"
    echo "  • Device: /dev/video10"
    echo "  • Use in Zoom/Meet: Select 'PiAssistantCam'"
    echo "  • Start manually: sudo /usr/local/bin/stream-to-virtual-cam.sh"
    echo ""
    
    log "🤖 Ollama API:"
    echo "  • URL: http://localhost:11434"
    echo "  • Model: llama3.2:3b"
    echo "  • Test: curl http://localhost:11434/api/version"
    echo ""
    
    if systemctl list-unit-files | grep -q pi-assistant.service; then
        log "🔧 Service Management:"
        echo "  • Start:   sudo systemctl start pi-assistant"
        echo "  • Stop:    sudo systemctl stop pi-assistant"
        echo "  • Status:  sudo systemctl status pi-assistant"
        echo "  • Logs:    sudo journalctl -u pi-assistant -f"
        echo ""
    fi
    
    warn "⚠️  IMPORTANT: Reboot recommended to activate all changes:"
    echo "     sudo reboot"
    echo ""
    
    log "📚 For more information, see:"
    echo "  • README.md"
    echo "  • pi-assistant/README.md"
    echo ""
    
    success "Setup script complete! Happy learning Dutch! 🇳🇱"
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    print_banner
    check_raspberry_pi
    
    # Run all setup steps
    update_system
    install_base_dependencies
    install_pi_hardware
    setup_virtual_camera
    install_ollama
    setup_python_environment
    configure_audio
    setup_database
    create_configuration
    create_systemd_services
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
