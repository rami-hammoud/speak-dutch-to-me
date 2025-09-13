#!/bin/bash

# Pi Assistant Setup Script for Raspberry Pi
# This script installs all dependencies and configures the system

set -e

echo "🤖 Setting up Pi Assistant..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This script is designed for Raspberry Pi. Some features may not work on other systems."
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    cmake \
    pkg-config \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libgdk-pixbuf2.0-dev \
    libpango1.0-dev \
    libgtk2.0-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    gfortran \
    libhdf5-dev \
    libhdf5-serial-dev \
    libhdf5-103 \
    libqt5gui5 \
    libqt5webkit5 \
    libqt5test5 \
    python3-pyqt5 \
    portaudio19-dev \
    espeak \
    espeak-data \
    libespeak1 \
    libespeak-dev \
    alsa-utils \
    pulseaudio \
    pulseaudio-utils

# Install Pi Camera dependencies
print_status "Installing camera dependencies..."
sudo apt install -y \
    libcamera-apps \
    libcamera-dev \
    python3-libcamera \
    python3-kms++ \
    python3-prctl \
    libatlas3-base \
    libatlas-base-dev

# Enable camera interface
print_status "Enabling camera interface..."
sudo raspi-config nonint do_camera 0

# Enable I2C and SPI (might be needed for some HAT functionalities)
print_status "Enabling I2C and SPI..."
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0

# Create virtual environment
print_status "Creating Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install Python packages
print_status "Installing Python dependencies..."

# Install basic packages first
pip install numpy==1.24.3

# Install OpenCV (this can take a while on Pi)
print_status "Installing OpenCV (this may take several minutes)..."
pip install opencv-python==4.8.1.78

# Install audio dependencies
print_status "Installing audio dependencies..."
pip install pyaudio SpeechRecognition pyttsx3

# Install web framework
print_status "Installing web framework..."
pip install fastapi uvicorn[standard] jinja2 python-multipart websockets aiohttp

# Install Pi-specific packages
print_status "Installing Raspberry Pi specific packages..."
pip install picamera2 RPi.GPIO psutil python-dotenv

# Create directories
print_status "Creating necessary directories..."
mkdir -p data logs static/css static/js static/images

# Create environment file
print_status "Creating environment configuration..."
cat > .env << 'EOF'
# Pi Assistant Configuration

# Server settings
HOST=0.0.0.0
PORT=8080
DEBUG=true

# OpenAI settings (add your API key here)
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4

# Ollama settings
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2

# Camera settings
CAMERA_ENABLED=true
CAMERA_WIDTH=640
CAMERA_HEIGHT=480

# Audio settings
AUDIO_INPUT_DEVICE=
AUDIO_OUTPUT_DEVICE=

# Display settings
FULLSCREEN=false
SCREEN_WIDTH=800
SCREEN_HEIGHT=480
EOF

# Install Ollama (optional)
read -p "Do you want to install Ollama for local AI models? (y/n): " install_ollama
if [[ $install_ollama =~ ^[Yy]$ ]]; then
    print_status "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    
    print_status "Starting Ollama service..."
    sudo systemctl enable ollama
    sudo systemctl start ollama
    
    print_status "Pulling default model (llama3.2)..."
    ollama pull llama3.2
fi

# Create systemd service file
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/pi-assistant.service > /dev/null << EOF
[Unit]
Description=Pi Assistant
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
ExecStart=$(pwd)/venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set up audio permissions
print_status "Setting up audio permissions..."
sudo usermod -a -G audio $USER

# Configure audio system
print_status "Configuring audio system..."
# Create ALSA config for better audio support
sudo tee /etc/asound.conf > /dev/null << 'EOF'
pcm.!default {
    type pulse
}
ctl.!default {
    type pulse
}
EOF

# Enable and start pulseaudio
sudo systemctl --global enable pulseaudio.service
sudo systemctl --global start pulseaudio.service

# Make scripts executable
chmod +x setup_pi_assistant.sh

print_success "Pi Assistant setup completed!"

echo ""
print_status "Next steps:"
echo "1. If you want to use OpenAI, add your API key to the .env file"
echo "2. Start the service: sudo systemctl enable pi-assistant && sudo systemctl start pi-assistant"
echo "3. Or run manually: source venv/bin/activate && python main.py"
echo "4. Access the web interface at http://your-pi-ip:8080"
echo ""
print_status "To check the status: sudo systemctl status pi-assistant"
print_status "To view logs: sudo journalctl -u pi-assistant -f"
echo ""
print_warning "You may need to reboot for all changes to take effect."

echo ""
echo "🎉 Setup complete! Your Pi Assistant is ready to use."
