# Raspberry Pi Setup Guide

This guide will help you set up the Dutch Learning AI Assistant on your Raspberry Pi.

## Prerequisites

- Raspberry Pi 4/5 (recommended 4GB+ RAM)
- Raspberry Pi OS (64-bit, Bookworm or later)
- Internet connection
- SD card with at least 32GB (64GB+ recommended for Ollama models)
- Optional: AI HAT+ camera module
- Optional: ReSpeaker microphone array

## Quick Start

### 1. Clone the Repository

```bash
cd ~
mkdir -p workspace
cd workspace
git clone <your-repo-url> speak-dutch-to-me
cd speak-dutch-to-me
```

### 2. Run the Setup Script

```bash
./setup_raspberry_pi.sh
```

This will install everything you need:
- ✅ System packages and dependencies
- ✅ Python virtual environment
- ✅ Ollama (local LLM) with llama3.2:3b model
- ✅ Camera and audio drivers
- ✅ Virtual camera for video calls
- ✅ Database with seed vocabulary
- ✅ Configuration files
- ✅ Optional: systemd services for auto-start

**Estimated time:** 30-60 minutes (depending on internet speed and Pi model)

### 3. Configure API Keys (Optional)

Edit the configuration file to add your API keys:

```bash
cd pi-assistant
nano .env
```

Add your keys:
```
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
BRAVE_SEARCH_API_KEY=your-key-here
```

> **Note:** The assistant works with Ollama (local) by default. API keys are optional.

### 4. Reboot

After setup completes, reboot to activate all changes:

```bash
sudo reboot
```

### 5. Start the Assistant

After reboot, start the assistant:

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
./start_assistant.sh
```

### 6. Access the Web Interface

Open your browser and go to:
```
http://<raspberry-pi-ip>:8080
```

To find your Pi's IP address:
```bash
hostname -I
```

## What Gets Installed

### System Packages
- Python 3 with virtual environment support
- Build tools (gcc, cmake, pkg-config)
- Audio libraries (ALSA, PulseAudio, PortAudio)
- Video libraries (libcamera, v4l2loopback, ffmpeg)
- I2C tools for hardware communication

### Python Environment
All dependencies from `requirements.txt`:
- FastAPI + Uvicorn (web server)
- SpeechRecognition (audio processing)
- OpenCV (computer vision)
- PiCamera2 (camera control)
- And more...

### Ollama
- Local LLM server running on your Pi
- Pre-installed model: llama3.2:3b (2GB)
- Service running at: `http://localhost:11434`

### Virtual Camera
- Device: `/dev/video10`
- Name: "PiAssistantCam"
- Use in Zoom, Meet, Teams, etc.

### Database
- SQLite database in `pi-assistant/data/`
- Pre-loaded with Dutch vocabulary
- Progress tracking enabled

## Hardware Setup

### Camera (AI HAT+)

1. Connect the camera ribbon cable to your Pi
2. The setup script will enable the camera interface
3. Test the camera:
```bash
rpicam-hello
```

### Audio (ReSpeaker)

1. Connect the ReSpeaker HAT to GPIO pins
2. The I2C interface will be enabled automatically
3. Test audio input:
```bash
arecord -l
```

## Features

### 🗣️ Voice Interface
- Speech recognition for pronunciation practice
- Text-to-speech for audio playback
- Multi-language support

### 📷 Camera Features
- Object detection for visual learning
- Virtual camera for video calls
- Real-time image processing

### 🎓 Dutch Learning
- Interactive vocabulary flashcards
- Grammar lessons and exercises
- Pronunciation scoring
- Progress tracking
- Daily challenges

### 🤖 AI Assistant
- Local LLM (Ollama) for privacy
- Optional cloud AI (OpenAI, Anthropic)
- Context-aware conversations
- Agentic capabilities (coming soon)

## Service Management

If you enabled systemd services during setup:

### Start/Stop Services
```bash
# Start the assistant
sudo systemctl start pi-assistant

# Stop the assistant
sudo systemctl stop pi-assistant

# Restart the assistant
sudo systemctl restart pi-assistant

# Check status
sudo systemctl status pi-assistant
```

### Enable/Disable Auto-Start
```bash
# Enable (start on boot)
sudo systemctl enable pi-assistant

# Disable
sudo systemctl disable pi-assistant
```

### View Logs
```bash
# Real-time logs
sudo journalctl -u pi-assistant -f

# Last 100 lines
sudo journalctl -u pi-assistant -n 100

# Logs since today
sudo journalctl -u pi-assistant --since today
```

## Virtual Camera

### Manual Start
```bash
sudo /usr/local/bin/stream-to-virtual-cam.sh
```

### Using in Video Calls

1. Open Zoom/Meet/Teams
2. Go to video settings
3. Select "PiAssistantCam" as your camera
4. You should see the feed from your Pi camera

### Check Virtual Camera
```bash
# List video devices
v4l2-ctl --list-devices

# Test the virtual camera
ffplay /dev/video10
```

## Troubleshooting

### Camera Not Working

```bash
# Check if camera is detected
vcgencmd get_camera

# Test camera
rpicam-still -o test.jpg

# Check camera permissions
sudo usermod -a -G video $USER
```

### Audio Issues

```bash
# List audio devices
arecord -l  # Input devices
aplay -l    # Output devices

# Test audio input
arecord -d 5 test.wav
aplay test.wav

# Restart PulseAudio
systemctl --user restart pulseaudio
```

### Ollama Not Starting

```bash
# Check Ollama status
sudo systemctl status ollama

# View Ollama logs
sudo journalctl -u ollama -f

# Restart Ollama
sudo systemctl restart ollama

# Test Ollama
curl http://localhost:11434/api/version
```

### Python Dependencies

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
source venv/bin/activate
pip install -r requirements.txt --force-reinstall
```

### Reset Configuration

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
rm .env
cp .env.example .env
nano .env
```

## Performance Optimization

### For Raspberry Pi 4 (4GB)
- Use Ollama with llama3.2:3b (default)
- Limit concurrent camera streams
- Consider disabling virtual camera if not needed

### For Raspberry Pi 5 (8GB)
- Can handle llama3.2:7b model
- Better camera performance
- Smoother multi-tasking

### Memory Management

```bash
# Check memory usage
free -h

# Check if swap is enabled
swapon --show

# Enable swap if needed (not recommended for SD cards)
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## Updating

```bash
cd ~/workspace/speak-dutch-to-me
git pull origin main
cd pi-assistant
source venv/bin/activate
pip install -r requirements.txt --upgrade
```

## Uninstalling

To remove the assistant:

```bash
# Stop services
sudo systemctl stop pi-assistant
sudo systemctl stop virtual-camera
sudo systemctl disable pi-assistant
sudo systemctl disable virtual-camera

# Remove service files
sudo rm /etc/systemd/system/pi-assistant.service
sudo rm /etc/systemd/system/virtual-camera.service
sudo systemctl daemon-reload

# Remove virtual camera script
sudo rm /usr/local/bin/stream-to-virtual-cam.sh

# Remove virtual camera module
sudo modprobe -r v4l2loopback
sudo rm /etc/modules-load.d/v4l2loopback.conf
sudo rm /etc/modprobe.d/v4l2loopback.conf

# Uninstall Ollama (optional)
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm /usr/local/bin/ollama
sudo rm -rf /usr/share/ollama

# Remove project directory
rm -rf ~/workspace/speak-dutch-to-me
```

## Support

For issues, questions, or contributions:
- Check the main README.md
- See pi-assistant/README.md for development docs
- Review logs: `~/workspace/speak-dutch-to-me/pi-assistant/logs/`

## Security Notes

- The web interface runs on port 8080 (accessible on local network)
- No authentication by default (add reverse proxy with auth for internet access)
- API keys stored in `.env` file (protect this file)
- Consider using firewall rules for production deployment

## Next Steps

After setup:
1. ✅ Test the web interface
2. ✅ Try the Dutch learning features
3. ✅ Practice pronunciation
4. ✅ Use the camera for object learning
5. ✅ Configure personal preferences
6. ✅ Set up daily learning goals

Happy learning Dutch! 🇳🇱 🚀
