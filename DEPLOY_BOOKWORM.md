# 🚀 Deploy to Fresh Raspberry Pi (Bookworm + Hailo AI HAT+)

## Prerequisites

- **Raspberry Pi 5** (required for Hailo AI HAT+)
- **Raspberry Pi OS Bookworm** (64-bit recommended)
- **Hailo AI HAT+** installed
- **IMX500 AI Camera** (optional, standard camera works too)
- **ReSpeaker 4-Mic Array** (optional, for voice input)
- **Internet connection**
- **Keyboard, mouse, display** or **SSH access**

---

## 🎯 One-Command Deployment

### Option 1: Direct Script Execution (Fastest)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/speak-dutch-to-me/main/setup_bookworm.sh | bash
```

### Option 2: Clone and Run (Recommended)

```bash
# 1. Clone the repository
cd ~
mkdir -p workspace
cd workspace
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me

# 2. Run setup
chmod +x setup_bookworm.sh
./setup_bookworm.sh
```

**That's it!** The script will:
- ✅ Verify Bookworm and Python 3.11
- ✅ Install all system dependencies
- ✅ Setup Hailo AI HAT+ support
- ✅ Install camera drivers (rpicam-still)
- ✅ Setup Python environment
- ✅ Install Ollama + llama3.2:3b
- ✅ Configure audio system
- ✅ Initialize database
- ✅ Create `.env` configuration
- ✅ Enable auto-start on boot (systemd)

---

## ⚙️ Post-Installation

### 1. Configure Settings (Optional)

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
nano .env
```

**Optional API keys:**
- `OPENAI_API_KEY` - For GPT-4 access
- `ANTHROPIC_API_KEY` - For Claude access
- `GOOGLE_CALENDAR_CREDENTIALS` - For calendar integration
- `TODOIST_API_KEY` - For task management

**Note:** The assistant works fully offline with Ollama, API keys are optional!

### 2. Reboot to Enable Auto-Start

```bash
sudo reboot
```

**After reboot, services start automatically!** No need to manually start anything.

### 3. Access the Web Interface

Open your browser to:
- **Main Dashboard:** `http://YOUR_PI_IP:8080`
- **Dutch Learning:** `http://YOUR_PI_IP:8080/dutch-learning`

### 4. Manage Services

```bash
# Check status
sudo systemctl status pi-assistant

# View live logs
sudo journalctl -u pi-assistant -f

# Restart if needed
sudo systemctl restart pi-assistant
```

Replace `YOUR_PI_IP` with your Pi's IP address (shown when starting).

---

## 🔧 Management Commands

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Start the assistant
./start_assistant.sh

# Stop the assistant
./stop_assistant.sh

# Check status
./status_assistant.sh

# View logs
tail -f logs/assistant.log
```

---

## ✅ Verification Checklist

After deployment, verify everything works:

```bash
cd ~/workspace/speak-dutch-to-me

# Run comprehensive verification
./verify_installation.sh
```

Should show:
- [x] Python 3.11 environment
- [x] System packages (OpenCV, NumPy)
- [x] Camera utilities (rpicam-still)
- [x] Hailo device detected
- [x] Ollama service running
- [x] Audio system configured
- [x] Database initialized
- [x] Direct camera access (no virtual camera)

---

## 🎥 Hailo AI HAT+ Specific Setup

### Check Hailo Device

```bash
# Check if Hailo is detected
lspci | grep -i hailo

# Check kernel module
lsmod | grep hailo

# Expected output:
# 0000:01:00.0 Co-processor: Hailo Technologies Ltd. Hailo-8 AI Processor (rev 01)
```

### Install Hailo Software (If Needed)

If Hailo device is detected but driver not loaded:

```bash
# Follow official Hailo setup
git clone https://github.com/hailo-ai/hailo-rpi5-examples.git
cd hailo-rpi5-examples
./install.sh
```

### Enable PCIe (If Hailo Not Detected)

```bash
# Enable PCIe in raspi-config
sudo raspi-config
# Navigate to: Interface Options > PCIe > Enable

# Reboot
sudo reboot
```

---

## 📸 Camera Configuration

### Check Available Cameras

```bash
# List connected cameras
rpicam-hello --list-cameras
```

**Expected output for IMX500:**
```
0 : imx500 [4056x3040] (/base/axi/pcie@120000/rp1/i2c@88000/imx500@1a)
```

**Standard camera:**
```
0 : imx519 [4656x3496] (/base/axi/pcie@120000/rp1/i2c@80000/imx519@1a)
```

### Test Camera

```bash
# Take a test photo
rpicam-still -o test.jpg

# View the photo (if GUI available)
gpicview test.jpg
```

---

## 🎤 Audio Configuration (ReSpeaker)

### Check Audio Devices

```bash
# List playback devices
aplay -l

# List capture devices
arecord -l
```

### Configure ReSpeaker

If using ReSpeaker 4-Mic Array:

```bash
# Install ReSpeaker drivers (if not auto-detected)
git clone https://github.com/respeaker/seeed-voicecard.git
cd seeed-voicecard
sudo ./install.sh

# Reboot
sudo reboot
```

---

## 🚨 Troubleshooting

### Issue: Hailo Device Not Detected

**Solution:**
```bash
# 1. Check physical connection
# 2. Enable PCIe
sudo raspi-config
# Interface Options > PCIe > Enable

# 3. Reboot and check again
sudo reboot
lspci | grep -i hailo
```

### Issue: Camera Busy Error

**Solution:**
```bash
# Kill any process using camera
sudo pkill -f rpicam
sudo pkill -f libcamera

# Try again
rpicam-still -o test.jpg
```

### Issue: Ollama Not Starting

**Solution:**
```bash
# Check service status
sudo systemctl status ollama

# Restart service
sudo systemctl restart ollama

# Check logs
sudo journalctl -u ollama -f
```

### Issue: Port 8080 Already in Use

**Solution:**
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Use the stop script (handles port conflicts)
./stop_assistant.sh

# Start again
./start_assistant.sh
```

---

## 🔄 Updating the Application

When new features are added:

```bash
cd ~/workspace/speak-dutch-to-me

# Stop the assistant
cd pi-assistant
./stop_assistant.sh

# Pull latest code
cd ..
git pull

# Restart
cd pi-assistant
./start_assistant.sh
```

---

## 🎯 Performance Optimization

### Enable Hailo Acceleration (Coming Soon)

The Hailo AI HAT+ will be used for:
- Object detection in camera feed
- Image recognition for vocabulary
- Face detection for user tracking
- Real-time video processing

### Optimize Ollama

```bash
# Check Ollama memory usage
ollama ps

# Pull a smaller model if needed
ollama pull llama3.2:1b  # Even faster on Pi 5
```

---

## 📊 System Requirements

### Minimum
- Raspberry Pi 5 (4GB RAM)
- 16GB SD card
- Bookworm OS
- Internet connection

### Recommended
- Raspberry Pi 5 (8GB RAM)
- 32GB SD card (or USB SSD)
- Hailo AI HAT+
- IMX500 AI Camera
- ReSpeaker 4-Mic Array
- Cooling fan/heatsink
- Stable 5V 5A power supply

---

## 🔐 Security Notes

### Firewall Configuration (Optional)

```bash
# Install ufw
sudo apt install ufw

# Allow SSH
sudo ufw allow ssh

# Allow web interface
sudo ufw allow 8080/tcp

# Enable firewall
sudo ufw enable
```

### Secure .env File

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Set proper permissions
chmod 600 .env
```

---

## 📚 Next Steps After Deployment

1. **Test Dutch Learning Features**
   - Try vocabulary learning
   - Test pronunciation feedback
   - Use camera for visual learning

2. **Configure Personal Assistant**
   - Connect Google Calendar
   - Add Todoist API key
   - Setup email integration

3. **Explore Voice Control**
   - Test voice commands
   - Configure wake word
   - Adjust microphone sensitivity

4. **Customize UI**
   - Access settings panel
   - Choose AI provider
   - Customize appearance

---

## 🆘 Getting Help

- **Check logs:** `tail -f ~/workspace/speak-dutch-to-me/pi-assistant/logs/assistant.log`
- **Run diagnostics:** `./verify_installation.sh`
- **Check status:** `./status_assistant.sh`
- **Read docs:** Check `DEVELOPMENT.md` and `NEXT_STEPS.md`

---

## ✨ Success Indicators

Your deployment is successful when:
- ✅ `./setup_bookworm.sh` completes without errors
- ✅ `./status_assistant.sh` shows "Pi Assistant is RUNNING"
- ✅ Web interface loads at `http://YOUR_PI_IP:8080`
- ✅ Ollama responds: `curl http://localhost:11434/api/version`
- ✅ Camera works: `rpicam-still -o test.jpg`
- ✅ Hailo detected: `lspci | grep -i hailo`

---

**🎉 You're ready to start learning Dutch and building amazing AI features!**

For development, see `DEVELOPMENT.md` and `NEXT_STEPS.md`.
