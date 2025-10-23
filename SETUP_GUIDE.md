# Dutch Learning AI Assistant - Raspberry Pi Setup

## Quick Start (Debian Trixie / Python 3.13+)

### One-Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/speak-dutch-to-me/main/setup_trixie.sh | bash
```

Or clone the repository first:

```bash
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me
chmod +x setup_trixie.sh
./setup_trixie.sh
```

### What Gets Installed

The setup script will install and configure:

1. **System Dependencies**
   - Python 3.13+ with all required libraries
   - Camera drivers (libcamera, picamera2)
   - Audio system (ALSA, PulseAudio)
   - Video processing (FFmpeg, v4l-utils)

2. **Python Environment**
   - Virtual environment with system site-packages
   - FastAPI web framework
   - Computer vision libraries (OpenCV, NumPy)
   - Audio libraries (PyAudio, SpeechRecognition)

3. **AI/LLM Support**
   - Ollama (local LLM engine)
   - llama3.2:3b model (optimized for Raspberry Pi)

4. **Virtual Camera** (optional)
   - v4l2loopback kernel module
   - Virtual camera device at `/dev/video10`
   - For use in Zoom, Google Meet, etc.

5. **Systemd Services** (optional)
   - Auto-start on boot
   - Automatic restart on failure

### Post-Installation Steps

1. **Configure the application:**
   ```bash
   cd pi-assistant
   nano .env
   ```
   Add your API keys (optional - Ollama works offline):
   - `OPENAI_API_KEY` - For GPT-4 access
   - `ANTHROPIC_API_KEY` - For Claude access
   - `BRAVE_SEARCH_API_KEY` - For web search

2. **Start the assistant:**
   ```bash
   cd pi-assistant
   ./start_assistant.sh
   ```

3. **Access the web interface:**
   - Open browser to: `http://YOUR_PI_IP:8080`
   - Dutch learning interface: `http://YOUR_PI_IP:8080/dutch-learning`

4. **Reboot (recommended):**
   ```bash
   sudo reboot
   ```
   This activates the virtual camera kernel module and ensures all services start properly.

## System Requirements

### Minimum Requirements
- Raspberry Pi 4 (2GB RAM) or newer
- 16GB SD card
- Debian Trixie (testing) or Bookworm with Python 3.13+
- Internet connection for initial setup

### Recommended
- Raspberry Pi 5 (4GB+ RAM)
- 32GB SD card (or USB SSD)
- Raspberry Pi Camera Module or USB webcam
- USB microphone and speaker

## Manual Setup (Alternative)

If you prefer manual installation:

### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Dependencies
```bash
sudo apt install -y \
    python3-full python3-pip python3-venv python3-dev \
    python3-opencv python3-numpy python3-picamera2 \
    libcamera-apps ffmpeg v4l-utils \
    portaudio19-dev alsa-utils pulseaudio
```

### 3. Install Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:3b
```

### 4. Setup Python Environment
```bash
cd pi-assistant
python3 -m venv --system-site-packages venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

### 5. Configure & Run
```bash
cp .env.example .env
nano .env  # Add your configuration
./start_assistant.sh
```

## Troubleshooting

### Python 3.13 Issues

If you encounter `pkgutil.ImpImporter` errors or setuptools issues:

1. **Use system packages for NumPy, OpenCV, etc:**
   ```bash
   sudo apt install python3-opencv python3-numpy python3-scipy python3-pil
   ```

2. **Create venv with system site-packages:**
   ```bash
   python3 -m venv --system-site-packages venv
   ```

3. **Use --no-build-isolation for pip installs:**
   ```bash
   pip install --no-build-isolation -r requirements.txt
   ```

See [PYTHON_313_TROUBLESHOOTING.md](PYTHON_313_TROUBLESHOOTING.md) for detailed troubleshooting.

### Virtual Camera Not Working

1. **Load the kernel module manually:**
   ```bash
   sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam"
   ```

2. **Check if device exists:**
   ```bash
   ls -l /dev/video*
   v4l2-ctl --list-devices
   ```

3. **Start the camera stream:**
   ```bash
   sudo /usr/local/bin/stream-to-virtual-cam.sh
   ```

### Ollama Not Responding

1. **Check service status:**
   ```bash
   sudo systemctl status ollama
   ```

2. **Restart Ollama:**
   ```bash
   sudo systemctl restart ollama
   ```

3. **Test API:**
   ```bash
   curl http://localhost:11434/api/version
   ```

### Web Interface Not Loading

1. **Check if service is running:**
   ```bash
   cd pi-assistant
   ./start_assistant.sh
   ```

2. **Check logs:**
   ```bash
   tail -f pi-assistant/logs/assistant.log
   ```

3. **Verify port is open:**
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

## Useful Commands

```bash
# Start the assistant
cd pi-assistant && ./start_assistant.sh

# View logs
tail -f pi-assistant/logs/assistant.log

# Check systemd service status
sudo systemctl status pi-assistant

# Restart service
sudo systemctl restart pi-assistant

# List Ollama models
ollama list

# Test Ollama
ollama run llama3.2:3b "Hello, speak Dutch to me!"

# Check camera
rpicam-hello --list-cameras
v4l2-ctl --list-devices

# Test audio
aplay -l  # List playback devices
arecord -l  # List capture devices
```

## CI/CD / Automated Deployment

For automated/non-interactive installation:

```bash
# Set environment variables
export NON_INTERACTIVE=true
export SKIP_PI_CHECK=true
export INSTALL_OLLAMA=true

# Run setup
./setup_trixie.sh
```

Or use command-line flags:

```bash
./setup_trixie.sh --help
```

## Additional Scripts

- **`verify_installation.sh`** - Test all components after installation
- **`manage_virtual_camera.sh`** - Control virtual camera stream

## Support

For issues and questions:
- Check [PYTHON_313_TROUBLESHOOTING.md](PYTHON_313_TROUBLESHOOTING.md)
- Review logs in `pi-assistant/logs/`
- Check GitHub Issues

## License

[Your License Here]
