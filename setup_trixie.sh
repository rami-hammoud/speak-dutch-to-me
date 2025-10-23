#!/usr/bin/env bash
# Raspberry Pi Setup Script for Dutch Learning AI Assistant
# Optimized for Debian Trixie (testing)
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
print_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[✓]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $*"; }
print_error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
print_step() { echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}STEP $1${NC}"; echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/pi-assistant"
step_num=1

# Print welcome banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Dutch Learning AI Assistant - Raspberry Pi Setup       ║
║   Optimized for Debian Trixie                             ║
║                                                           ║
║   This will install:                                      ║
║   • Python environment & dependencies                     ║
║   • Ollama (local LLM)                                    ║
║   • Camera & Audio support (optional)                     ║
║   • Virtual camera for Zoom/Meet (optional)               ║
║   • Database & seed data                                  ║
║   • Systemd services (optional)                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Detect OS version
detect_os() {
    if grep -q "trixie" /etc/os-release 2>/dev/null; then
        OS_VERSION="trixie"
        print_success "Detected Debian Trixie (testing) - perfect!"
    elif grep -q "bookworm" /etc/os-release 2>/dev/null; then
        OS_VERSION="bookworm"
        print_info "Detected Debian Bookworm"
    elif grep -q "bullseye" /etc/os-release 2>/dev/null; then
        OS_VERSION="bullseye"
        print_info "Detected Debian Bullseye"
    else
        OS_VERSION="unknown"
        print_warning "Unknown OS version, proceeding with caution..."
    fi
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [[ -f /proc/cpuinfo ]] && grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_success "Running on Raspberry Pi - all features will be available"
        IS_RPI=true
    else
        print_warning "Not running on Raspberry Pi - hardware features will be limited"
        IS_RPI=false
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && print_error "Setup cancelled"
    fi
}

# ============================================================================
# STEP 1: System Update
# ============================================================================
update_system() {
    print_step "$step_num/9: Updating System Packages"
    ((step_num++))
    
    print_info "Updating package lists..."
    sudo apt update
    
    print_info "Upgrading installed packages (this may take a while)..."
    sudo apt upgrade -y
    
    print_success "System updated successfully"
}

# ============================================================================
# STEP 2: Install Base Dependencies
# ============================================================================
install_base_dependencies() {
    print_step "$step_num/9: Installing Base Dependencies"
    ((step_num++))
    
    print_info "Installing Python and build tools..."
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
        ffmpeg \
        v4l-utils
    
    print_success "Base dependencies installed"
}

# ============================================================================
# STEP 3: Install Hardware Support (Camera & Audio)
# ============================================================================
install_hardware_support() {
    print_step "$step_num/9: Installing Hardware Support"
    ((step_num++))
    
    if [ "$IS_RPI" = true ]; then
        # Camera support
        print_info "Installing camera support..."
        sudo apt install -y \
            libcamera-apps \
            libcamera-tools \
            libcamera-dev \
            python3-libcamera \
            python3-picamera2 \
            rpicam-apps \
            python3-opencv 2>/dev/null || {
                print_warning "Some camera packages not available - will try pip alternatives"
            }
        
        # Kernel headers for v4l2loopback
        print_info "Installing kernel headers for virtual camera..."
        if [ "$OS_VERSION" = "trixie" ] || [ "$OS_VERSION" = "bookworm" ]; then
            # Try multiple header package names
            sudo apt install -y linux-headers-$(uname -r) 2>/dev/null || \
            sudo apt install -y linux-headers-rpi-v8 2>/dev/null || \
            sudo apt install -y linux-headers-rpi-2712 2>/dev/null || \
            sudo apt install -y linux-headers-arm64 2>/dev/null || {
                print_warning "Kernel headers not found - virtual camera may not work"
                print_info "This is OK, you can add it later if needed"
            }
        else
            sudo apt install -y raspberrypi-kernel-headers 2>/dev/null || {
                print_warning "Kernel headers not available"
            }
        fi
        
        # v4l2loopback for virtual camera
        print_info "Installing v4l2loopback for virtual camera..."
        sudo apt install -y v4l2loopback-dkms v4l2loopback-utils 2>/dev/null || {
            print_warning "v4l2loopback not available - virtual camera disabled"
            print_info "This is optional, you can install later with:"
            print_info "  sudo apt install v4l2loopback-dkms"
        }
        
        # Audio support
        print_info "Installing audio support..."
        sudo apt install -y \
            libasound2-dev \
            portaudio19-dev \
            libportaudio2 \
            libportaudiocpp0 \
            pulseaudio \
            pulseaudio-module-bluetooth \
            alsa-utils 2>/dev/null || {
                print_warning "Some audio packages not available"
            }
        
        # Try to install python3-pyaudio from repos
        if ! sudo apt install -y python3-pyaudio 2>/dev/null; then
            print_info "python3-pyaudio not in repos, will install via pip later"
        fi
        
        # I2C tools for ReSpeaker
        print_info "Installing I2C tools..."
        sudo apt install -y i2c-tools 2>/dev/null || true
        
        # Enable camera and I2C
        print_info "Enabling camera and I2C interfaces..."
        if command -v raspi-config >/dev/null 2>&1; then
            sudo raspi-config nonint do_camera 0 2>/dev/null || print_info "Camera already enabled"
            sudo raspi-config nonint do_i2c 0 2>/dev/null || print_info "I2C already enabled"
        else
            # Manual config for Trixie
            print_info "Enabling via config.txt..."
            CONFIG_FILE="/boot/firmware/config.txt"
            if [ ! -f "$CONFIG_FILE" ]; then
                CONFIG_FILE="/boot/config.txt"
            fi
            
            if [ -f "$CONFIG_FILE" ]; then
                if ! grep -q "^camera_auto_detect=1" "$CONFIG_FILE" 2>/dev/null; then
                    echo "camera_auto_detect=1" | sudo tee -a "$CONFIG_FILE" >/dev/null
                fi
                if ! grep -q "^dtparam=i2c_arm=on" "$CONFIG_FILE" 2>/dev/null; then
                    echo "dtparam=i2c_arm=on" | sudo tee -a "$CONFIG_FILE" >/dev/null
                fi
            fi
        fi
        
        # Try to load v4l2loopback module
        print_info "Loading v4l2loopback kernel module..."
        if lsmod | grep -q v4l2loopback; then
            print_success "v4l2loopback already loaded"
        elif sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam" exclusive_caps=1 2>/dev/null; then
            print_success "v4l2loopback module loaded"
            
            # Configure to load on boot
            echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
            echo "options v4l2loopback devices=1 video_nr=10 card_label=\"PiAssistantCam\" exclusive_caps=1" | \
                sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
        else
            print_warning "v4l2loopback module failed to load"
            print_info "Virtual camera disabled (this is optional)"
        fi
        
        if [ -e /dev/video10 ]; then
            print_success "Virtual camera available at /dev/video10"
        fi
        
        print_success "Hardware support installation complete"
    else
        print_warning "Not on Pi - skipping hardware support"
        print_info "Will install OpenCV via pip instead"
    fi
}

# ============================================================================
# STEP 4: Install Ollama
# ============================================================================
install_ollama() {
    print_step "$step_num/9: Installing Ollama (Local LLM)"
    ((step_num++))
    
    if command -v ollama >/dev/null 2>&1; then
        print_success "Ollama already installed"
    else
        print_info "Installing Ollama (this may take a few minutes)..."
        curl -fsSL https://ollama.com/install.sh | sh
        
        print_info "Starting Ollama service..."
        sudo systemctl enable ollama 2>/dev/null || true
        sudo systemctl start ollama 2>/dev/null || true
        sleep 3
        
        print_success "Ollama installed"
    fi
    
    print_info "Pulling llama3.2:3b model (this may take several minutes)..."
    if ollama list | grep -q "llama3.2:3b"; then
        print_success "llama3.2:3b already downloaded"
    else
        ollama pull llama3.2:3b
        print_success "llama3.2:3b model downloaded"
    fi
}

# ============================================================================
# STEP 5: Setup Python Environment
# ============================================================================
setup_python_environment() {
    print_step "$step_num/9: Setting Up Python Virtual Environment"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    
    if [ -d "venv" ]; then
        print_info "Virtual environment already exists"
    else
        print_info "Creating virtual environment..."
        python3 -m venv venv
    fi
    
    print_info "Activating virtual environment..."
    source venv/bin/activate
    
    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel
    
    print_info "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Install pyaudio if not available from apt
    if ! python3 -c "import pyaudio" 2>/dev/null; then
        print_info "Installing PyAudio via pip..."
        pip install pyaudio 2>/dev/null || {
            print_warning "PyAudio installation failed - audio features may be limited"
            print_info "You can install it later with: pip install pyaudio"
        }
    fi
    
    # Install OpenCV if not from apt (non-Pi systems)
    if [ "$IS_RPI" = false ]; then
        print_info "Installing OpenCV via pip..."
        pip install opencv-python 2>/dev/null || true
    fi
    
    print_success "Python environment ready"
}

# ============================================================================
# STEP 6: Initialize Database
# ============================================================================
initialize_database() {
    print_step "$step_num/9: Initializing Database"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    source venv/bin/activate
    
    print_info "Creating data directory..."
    mkdir -p data
    
    print_info "Loading seed vocabulary data..."
    if [ -f "load_seed_data.py" ]; then
        python load_seed_data.py <<< "y" || {
            print_warning "Failed to load seed data - you can do this later"
        }
    else
        print_warning "load_seed_data.py not found - skipping seed data"
    fi
    
    print_success "Database initialized"
}

# ============================================================================
# STEP 7: Configure Environment
# ============================================================================
configure_environment() {
    print_step "$step_num/9: Configuring Environment"
    ((step_num++))
    
    cd "$PROJECT_DIR"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_info "Creating .env from template..."
            cp .env.example .env
            print_success ".env file created"
        else
            print_warning ".env.example not found - you'll need to create .env manually"
        fi
    else
        print_success ".env already exists"
    fi
    
    # Create logs directory
    print_info "Creating logs directory..."
    mkdir -p logs
    
    print_success "Environment configured"
}

# ============================================================================
# STEP 8: Setup Systemd Services (Optional)
# ============================================================================
setup_systemd_services() {
    print_step "$step_num/9: Setting Up Systemd Services (Optional)"
    ((step_num++))
    
    read -p "Would you like to set up systemd services for auto-start? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Creating systemd service for Pi Assistant..."
        
        cat << EOF | sudo tee /etc/systemd/system/pi-assistant.service >/dev/null
[Unit]
Description=Dutch Learning AI Assistant
After=network.target ollama.service
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$PROJECT_DIR/venv/bin/uvicorn main:assistant.app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        print_success "Systemd service created"
        
        read -p "Enable service to start on boot? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl enable pi-assistant.service
            print_success "Service enabled for auto-start"
        fi
        
        read -p "Start service now? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl start pi-assistant.service
            print_success "Service started"
            print_info "Check status with: sudo systemctl status pi-assistant"
        fi
    else
        print_info "Skipping systemd setup"
        print_info "You can start manually with: ./start_assistant.sh"
    fi
}

# ============================================================================
# STEP 9: Final Steps
# ============================================================================
final_steps() {
    print_step "$step_num/9: Setup Complete!"
    ((step_num++))
    
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✅ Setup Complete!                                      ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_success "All components installed successfully"
    echo
    
    # Get IP address
    IP_ADDR=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    print_info "Next steps:"
    echo
    echo "  1. Review configuration:"
    echo "     nano $PROJECT_DIR/.env"
    echo
    echo "  2. Start the assistant:"
    echo "     cd $PROJECT_DIR"
    echo "     ./start_assistant.sh"
    echo
    echo "  3. Access the web interface:"
    echo "     http://$IP_ADDR:8080"
    echo "     http://$IP_ADDR:8080/dutch-learning"
    echo
    
    if [ "$IS_RPI" = true ]; then
        if ! lsmod | grep -q v4l2loopback; then
            echo "  ⚠️  Virtual camera not loaded - reboot recommended:"
            echo "     sudo reboot"
            echo
        fi
    fi
    
    print_info "Useful commands:"
    echo "  • Start: cd $PROJECT_DIR && ./start_assistant.sh"
    echo "  • Logs: tail -f $PROJECT_DIR/logs/assistant.log"
    echo "  • Status: sudo systemctl status pi-assistant"
    echo "  • Ollama: ollama list"
    echo
    
    print_success "Happy learning Dutch! 🇳🇱"
}

# ============================================================================
# Main Setup Flow
# ============================================================================
main() {
    print_banner
    detect_os
    check_raspberry_pi
    
    update_system
    install_base_dependencies
    install_hardware_support
    install_ollama
    setup_python_environment
    initialize_database
    configure_environment
    setup_systemd_services
    final_steps
}

# Run main function
main

