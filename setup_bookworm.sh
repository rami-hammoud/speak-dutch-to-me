#!/usr/bin/env bash
# Raspberry Pi Setup Script for Dutch Learning AI Assistant
# Optimized for Raspberry Pi OS Bookworm (for Hailo AI HAT+ compatibility)
# Python 3.11 compatible
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
step() { echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}STEP $1${NC}"; echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/pi-assistant"
VENV_DIR="$PROJECT_DIR/venv"
DATA_DIR="$PROJECT_DIR/data"
LOGS_DIR="$PROJECT_DIR/logs"
step_num=1

# CI/CD Mode
NON_INTERACTIVE=${NON_INTERACTIVE:-false}
SKIP_PI_CHECK=${SKIP_PI_CHECK:-false}
INSTALL_OLLAMA=${INSTALL_OLLAMA:-true}
ENABLE_SYSTEMD=${ENABLE_SYSTEMD:-false}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive|-n)
            NON_INTERACTIVE=true
            shift
            ;;
        --skip-pi-check)
            SKIP_PI_CHECK=true
            shift
            ;;
        --enable-systemd)
            ENABLE_SYSTEMD=true
            shift
            ;;
        --skip-ollama)
            INSTALL_OLLAMA=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Raspberry Pi OS Bookworm Setup for Dutch Learning AI Assistant"
            echo "Optimized for Hailo AI HAT+ compatibility"
            echo ""
            echo "Options:"
            echo "  -n, --non-interactive    Run without prompts (CI/CD mode)"
            echo "  --skip-pi-check          Skip Raspberry Pi hardware check"
            echo "  --enable-systemd         Enable systemd services automatically"
            echo "  --skip-ollama            Skip Ollama installation"
            echo "  -h, --help               Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  NON_INTERACTIVE=true     Same as --non-interactive"
            echo "  SKIP_PI_CHECK=true       Same as --skip-pi-check"
            echo "  ENABLE_SYSTEMD=true      Same as --enable-systemd"
            echo "  INSTALL_OLLAMA=false     Same as --skip-ollama"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

# Print welcome banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Dutch Learning AI Assistant - Raspberry Pi Setup       ║
║   Raspberry Pi OS Bookworm + Hailo AI HAT+                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check OS version
check_os_version() {
    log "Checking OS version..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log "OS: $PRETTY_NAME"
        
        # Check for Bookworm
        if [[ "$VERSION_CODENAME" == "bookworm" ]]; then
            success "Running Raspberry Pi OS Bookworm ✓"
        else
            warn "Not running Bookworm (detected: $VERSION_CODENAME)"
            warn "Hailo AI HAT+ is optimized for Bookworm"
            if [[ "$NON_INTERACTIVE" == "false" ]]; then
                read -p "Continue anyway? [y/N]: " -n 1 -r
                echo
                [[ ! $REPLY =~ ^[Yy]$ ]] && error "Setup cancelled"
            fi
        fi
    fi
    
    # Check Python version
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    log "Python version: $PYTHON_VERSION"
    
    if [[ "$PYTHON_VERSION" == 3.11.* ]]; then
        success "Python 3.11 detected ✓"
    else
        warn "Expected Python 3.11, found $PYTHON_VERSION"
    fi
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [[ "$SKIP_PI_CHECK" == "true" ]]; then
        warn "Skipping Raspberry Pi hardware check"
        return 0
    fi
    
    log "Checking Raspberry Pi hardware..."
    
    if [[ ! -f /proc/cpuinfo ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        warn "Not running on Raspberry Pi detected."
        warn "Some hardware features (camera, GPIO, Hailo) may not work."
        if [[ "$NON_INTERACTIVE" == "false" ]]; then
            read -p "Continue anyway? [y/N]: " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && error "Setup cancelled"
        fi
    else
        # Check for Pi 5
        if grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
            success "Raspberry Pi 5 detected ✓"
        else
            warn "Not running on Raspberry Pi 5"
            warn "Hailo AI HAT+ requires Raspberry Pi 5"
        fi
    fi
}

# ============================================================================
# STEP 1: System Update
# ============================================================================
update_system() {
    step "$step_num/10: Updating System Packages"
    ((step_num++))
    
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
    step "$step_num/10: Installing Base Dependencies"
    ((step_num++))
    
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
        pkg-config \
        lsof \
        net-tools
    
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
    step "$step_num/10: Installing Raspberry Pi Hardware Support"
    ((step_num++))
    
    log "Installing camera support..."
    sudo apt install -y \
        raspberrypi-kernel-headers \
        libcamera-apps \
        libcamera-dev \
        python3-libcamera \
        python3-picamera2
    
    log "Installing system Python libraries (recommended for stability)..."
    sudo apt install -y \
        python3-opencv \
        python3-numpy \
        python3-pil \
        python3-scipy || warn "Some Python libraries not available"
    
    # Try to install PyAudio from system
    sudo apt install -y python3-pyaudio || warn "PyAudio not available from apt"
    
    success "System Python packages installed"
    
    # Enable camera interface
    log "Enabling camera interface..."
    if command -v raspi-config &>/dev/null; then
        sudo raspi-config nonint do_camera 0 || warn "Camera interface already enabled or not available"
    fi
    
    # Enable I2C for audio HATs and sensors
    log "Enabling I2C interface..."
    if command -v raspi-config &>/dev/null; then
        sudo raspi-config nonint do_i2c 0 || warn "I2C interface already enabled or not available"
    fi
    
    success "Raspberry Pi hardware support installed"
}

# ============================================================================
# STEP 4: Install Hailo AI HAT+ Support
# ============================================================================
install_hailo_support() {
    step "$step_num/10: Checking Hailo AI HAT+ Support"
    ((step_num++))
    
    log "Checking for Hailo device..."
    
    # Check if Hailo device is present
    if lspci | grep -i hailo &>/dev/null; then
        success "Hailo device detected!"
        
        # Check for Hailo driver
        if lsmod | grep -q hailo; then
            success "Hailo kernel module loaded"
        else
            warn "Hailo kernel module not loaded"
            log "To install Hailo software, follow: https://github.com/hailo-ai/hailo-rpi5-examples"
        fi
    else
        warn "Hailo device not detected"
        log "If you have Hailo AI HAT+ installed:"
        log "  1. Ensure it's properly seated"
        log "  2. Enable PCIe in raspi-config"
        log "  3. Reboot and run setup again"
    fi
    
    # Check for IMX500 AI camera
    log "Checking for IMX500 AI Camera..."
    if rpicam-hello --list-cameras 2>&1 | grep -i imx500 &>/dev/null; then
        success "IMX500 AI Camera detected!"
    else
        log "IMX500 AI Camera not detected (using standard camera)"
    fi
}

# ============================================================================
# STEP 5: Install Ollama (Local LLM)
# ============================================================================
install_ollama() {
    step "$step_num/9: Installing Ollama (Local LLM)"
    ((step_num++))
    
    if [[ "$INSTALL_OLLAMA" == "false" ]]; then
        warn "Skipping Ollama installation (--skip-ollama flag set)"
        return 0
    fi
    
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
        
        log "Pulling llama3.2:3b model (optimized for Pi, this will take a while)..."
        ollama pull llama3.2:3b
        
        success "Ollama installed and llama3.2:3b model downloaded"
    fi
    
    # Verify Ollama is running
    if systemctl is-active --quiet ollama; then
        success "Ollama service is running"
    else
        warn "Ollama service is not running. Starting it..."
        sudo systemctl start ollama
        sleep 3
        if systemctl is-active --quiet ollama; then
            success "Ollama service started"
        else
            warn "Could not start Ollama. You may need to start it manually."
        fi
    fi
}

# ============================================================================
# STEP 6: Setup Python Virtual Environment
# ============================================================================
setup_python_environment() {
    step "$step_num/9: Setting Up Python Virtual Environment"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    
    if [[ -d "$VENV_DIR" ]]; then
        warn "Virtual environment already exists. Removing old environment..."
        rm -rf "$VENV_DIR"
    fi
    
    log "Creating Python virtual environment with system packages..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    
    log "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"
    
    log "Upgrading pip and build tools..."
    pip install --upgrade pip
    pip install --upgrade setuptools wheel
    
    log "Installing core web framework dependencies..."
    pip install fastapi uvicorn jinja2 python-dotenv websockets || error "Failed to install web framework"
    
    log "Installing HTTP client libraries..."
    pip install httpx aiohttp requests || warn "Some HTTP libraries failed (non-critical)"
    
    log "Installing AI/LLM libraries (optional)..."
    pip install anthropic openai || warn "AI libraries failed (optional - can add later)"
    
    log "Installing database and utilities..."
    pip install aiosqlite psutil python-multipart || warn "Some utilities failed"
    
    log "Installing audio libraries (optional)..."
    pip install SpeechRecognition pyttsx3 || warn "Audio libraries skipped - using system packages"
    
    log "Installing remaining dependencies from requirements.txt..."
    if [[ -f requirements.txt ]]; then
        pip install -r requirements.txt 2>&1 | tee /tmp/pip-install.log || {
            warn "Some optional packages failed (this is OK if using system packages)"
        }
    fi
    
    log "Verifying critical imports..."
    python -c "import fastapi, uvicorn; print('✓ Web framework: OK')" || error "Web framework not working"
    python -c "import cv2, numpy; print('✓ Computer vision: OK')" || warn "OpenCV not available (optional)"
    python -c "import sqlite3; print('✓ Database: OK')" || error "Database not working"
    
    deactivate
    
    success "Python virtual environment configured"
    log "Note: Using system packages for OpenCV, NumPy (better compatibility)"
}

# ============================================================================
# STEP 7: Configure Audio System
# ============================================================================
configure_audio() {
    step "$step_num/9: Configuring Audio System"
    ((step_num++))
    
    log "Enabling PulseAudio for user..."
    systemctl --user enable pulseaudio.service 2>/dev/null || true
    systemctl --user start pulseaudio.service 2>/dev/null || true
    
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
    step "$step_num/9: Setting Up Database and Seed Data"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    
    # Create directories
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
# STEP 9: Create Configuration Files and Enable Auto-Start
# ============================================================================
create_configuration() {
    step "$step_num/9: Creating Configuration Files"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    
    # Create .env file from template
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            log "Creating .env from template..."
            cp .env.example .env
            success ".env file created from template"
        else
            warn ".env.example not found - creating basic .env"
            cat > .env << 'ENV_CONFIG'
# Server Settings
HOST=0.0.0.0
PORT=8080
DEBUG=true

# Directories
DATA_DIR=./data
LOGS_DIR=./logs

# AI Providers
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b

# Camera Settings
CAMERA_ENABLED=true
CAMERA_VFLIP=true
CAMERA_HFLIP=true

# Audio Settings
AUDIO_ENABLED=true

# MCP Server Settings
MCP_ENABLED=true
MCP_PORT=8081

# Dutch Learning
DUTCH_VOCABULARY_DB=./data/dutch_vocab.db
PROGRESS_TRACKING=true
ENV_CONFIG
            success ".env file created"
        fi
    else
        success ".env file already exists"
    fi
    
    # Make scripts executable
    chmod +x start_assistant.sh 2>/dev/null || true
    chmod +x stop_assistant.sh 2>/dev/null || true
    chmod +x status_assistant.sh 2>/dev/null || true
    
    success "Configuration complete"
}

# ============================================================================
# Create Systemd Services for Auto-Start on Boot
# ============================================================================
create_systemd_services() {
    echo ""
    log "Creating systemd services for automatic startup on boot..."
    
    log "Creating pi-assistant systemd service..."
    sudo tee /etc/systemd/system/pi-assistant.service >/dev/null <<SERVICE
[Unit]
Description=Dutch Learning AI Assistant
After=network.target ollama.service
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$VENV_DIR/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE
    
    log "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    log "Enabling services to start on boot..."
    sudo systemctl enable ollama.service || warn "Ollama service already enabled"
    sudo systemctl enable pi-assistant.service
    
    success "Services configured to start automatically on boot"
    log "Ollama and Pi Assistant will start automatically after reboot"
}

# ============================================================================
# Final Steps
# ============================================================================
final_steps() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║   ✅ Setup Complete!                                      ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    success "All components installed successfully"
    echo ""
    
    # Get IP address
    IP_ADDR=$(hostname -I | awk '{print $1}')
    
    log "📋 Next steps:"
    echo ""
    echo "  1. Review configuration (optional):"
    echo "     nano $PROJECT_DIR/.env"
    echo ""
    echo "  2. Reboot to enable auto-start services:"
    echo "     sudo reboot"
    echo ""
    echo "  3. After reboot, access the web interface:"
    echo "     http://$IP_ADDR:8080"
    echo "     http://$IP_ADDR:8080/dutch-learning"
    echo ""
    
    success "✨ Services will start automatically on boot!"
    echo ""
    
    log "🔧 Useful commands:"
    echo "  • Status:  sudo systemctl status pi-assistant"
    echo "  • Logs:    sudo journalctl -u pi-assistant -f"
    echo "  • Restart: sudo systemctl restart pi-assistant"
    echo "  • Stop:    sudo systemctl stop pi-assistant"
    echo "  • Ollama:  ollama list"
    echo ""
    
    success "Happy learning Dutch! 🇳🇱"
}

# ============================================================================
# Main Setup Flow
# ============================================================================
main() {
    print_banner
    check_os_version
    check_raspberry_pi
    
    update_system
    install_base_dependencies
    install_pi_hardware
    install_hailo_support
    install_ollama
    setup_python_environment
    configure_audio
    setup_database
    create_configuration
    create_systemd_services
    final_steps
}

# Run main function
main
