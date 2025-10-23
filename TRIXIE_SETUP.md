# 🍓 Trixie Setup Instructions

## For Debian Trixie (Testing) on Raspberry Pi

You're running **Debian Trixie** which is newer and has some package differences. I've created an optimized setup script for you!

---

## Quick Setup (Recommended)

```bash
# On your Raspberry Pi with Trixie
cd ~/workspace/speak-dutch-to-me
./setup_raspberry_pi_trixie.sh
```

This script will:
- ✅ Detect Trixie automatically
- ✅ Install all required packages
- ✅ Handle missing kernel headers gracefully
- ✅ Set up Python environment
- ✅ Install Ollama and models
- ✅ Initialize database
- ✅ Offer optional systemd services

**Time:** ~15-30 minutes depending on your internet connection

---

## Key Differences from Bookworm

### 1. Kernel Headers
Trixie uses `linux-headers-*` instead of `raspberrypi-kernel-headers`:
```bash
# The script tries these in order:
linux-headers-$(uname -r)
linux-headers-rpi-v8
linux-headers-rpi-2712
linux-headers-arm64
```

### 2. Camera Support
Camera packages work the same, but config location may vary:
- `/boot/firmware/config.txt` (newer)
- `/boot/config.txt` (fallback)

### 3. Virtual Camera
v4l2loopback may not compile if headers are missing - **this is OK!**
Virtual camera is optional and only needed for Zoom/Meet integration.

---

## Step-by-Step Manual Setup (If Automated Fails)

### 1. Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Core Packages
```bash
sudo apt install -y \
    python3-full python3-pip python3-venv python3-dev \
    git curl wget build-essential cmake pkg-config \
    ffmpeg v4l-utils
```

### 3. Install Hardware Support (Optional)
```bash
# Camera
sudo apt install -y \
    libcamera-apps libcamera-tools libcamera-dev \
    python3-libcamera python3-picamera2 rpicam-apps

# Audio
sudo apt install -y \
    libasound2-dev portaudio19-dev libportaudio2 \
    pulseaudio alsa-utils

# I2C (for ReSpeaker)
sudo apt install -y i2c-tools
```

### 4. Install Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
ollama pull llama3.2:3b
```

### 5. Setup Python Environment
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 6. Initialize Database
```bash
python load_seed_data.py
```

### 7. Configure & Start
```bash
cp .env.example .env
nano .env  # Edit if needed
./start_assistant.sh
```

---

## Troubleshooting

### Package Not Found Errors

**Error:** `Unable to locate package raspberrypi-kernel-headers`

**Solution:** This is expected on Trixie! The script handles it automatically by trying alternatives. Virtual camera is optional.

---

### V4L2Loopback Fails

**Error:** `Failed to load v4l2loopback module`

**Solution:** Virtual camera is **optional**. Skip it for now:
```bash
# You can still use physical camera and all other features
# Virtual camera is only for Zoom/Meet overlay
```

To add later:
```bash
sudo apt install v4l2loopback-dkms
sudo modprobe v4l2loopback devices=1 video_nr=10
```

---

### PyAudio Installation Fails

**Error:** `Failed to install pyaudio`

**Solution:** Try system package:
```bash
sudo apt install python3-pyaudio
```

Or skip audio features for now (pronunciation will be limited).

---

### Camera Not Detected

**Check camera is enabled:**
```bash
# Check config
cat /boot/firmware/config.txt | grep camera

# Should see:
# camera_auto_detect=1

# If not, add it:
echo "camera_auto_detect=1" | sudo tee -a /boot/firmware/config.txt
sudo reboot
```

**After reboot:**
```bash
# List cameras
rpicam-hello --list-cameras

# Test camera
rpicam-hello
```

---

### Ollama Service Won't Start

**Check status:**
```bash
sudo systemctl status ollama
```

**Manual start:**
```bash
ollama serve &
```

---

## What Works Without Optional Features

Even if hardware features fail, you'll still have:

✅ **Full Dutch Learning System**
- Vocabulary flashcards
- Grammar exercises  
- Progress tracking
- Translation service
- Web interface

✅ **AI Integration**
- Ollama local LLM
- Chat interface
- Context management

✅ **Core Features**
- Database
- API endpoints
- Web UI

---

## Testing After Setup

### 1. Test Web Interface
```bash
# Find your IP
hostname -I

# Access at:
http://<YOUR_IP>:8080
http://<YOUR_IP>:8080/dutch-learning
```

### 2. Test Ollama
```bash
ollama list
ollama run llama3.2:3b "Say hello in Dutch"
```

### 3. Test Camera (if installed)
```bash
rpicam-hello --timeout 5000
```

### 4. Check Logs
```bash
tail -f ~/workspace/speak-dutch-to-me/pi-assistant/logs/assistant.log
```

---

## Performance on Trixie

Trixie is the **testing** branch and may have:
- ✅ Newer packages
- ✅ Better performance
- ⚠️ Occasional breaking changes
- ⚠️ Less stable than Bookworm

For production, Bookworm is recommended. For development, Trixie is great!

---

## Getting Help

If setup fails:

1. **Run with verbose output:**
   ```bash
   bash -x ./setup_raspberry_pi_trixie.sh 2>&1 | tee setup.log
   ```

2. **Check the log:**
   ```bash
   cat setup.log | grep -i error
   ```

3. **Manual minimal setup:**
   ```bash
   # Just get software running (no hardware)
   cd ~/workspace/speak-dutch-to-me/pi-assistant
   python3 -m venv venv
   source venv/bin/activate
   pip install fastapi uvicorn jinja2 aiohttp
   uvicorn main:assistant.app --host 0.0.0.0 --port 8080
   ```

---

## After Setup

### Start the Assistant
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
./start_assistant.sh
```

### Enable Auto-Start
```bash
sudo systemctl enable pi-assistant
sudo systemctl start pi-assistant
```

### Check Status
```bash
sudo systemctl status pi-assistant
sudo journalctl -u pi-assistant -f
```

---

## Next Steps

Once running:

1. ✅ Test web interface
2. ✅ Try Dutch learning features
3. ✅ Add your own vocabulary
4. ✅ Practice pronunciation
5. ✅ Test camera (if available)
6. 🚀 Start learning Dutch!

---

**Happy Learning! 🇳🇱🍓**
