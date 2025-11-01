# 🔧 Quick Fix for Choppy Camera & Auto-Start Issues

## Current Issues
1. ❌ Camera is choppy (caused by v4l2loopback virtual camera)
2. ❌ Services don't auto-start on boot

## ✅ Solutions Applied

### 1. Remove Virtual Camera (Fix Choppy Performance)

Run this on your Pi to remove the virtual camera setup:

```bash
cd ~/workspace/speak-dutch-to-me
./cleanup_virtual_camera.sh
```

Or manually:
```bash
# Unload the module
sudo modprobe -r v4l2loopback

# Remove boot configs
sudo rm /etc/modules-load.d/v4l2loopback.conf
sudo rm /etc/modprobe.d/v4l2loopback.conf

# Optional: Remove packages
sudo apt remove -y v4l2loopback-dkms v4l2loopback-utils
sudo apt autoremove -y
```

### 2. Enable Auto-Start on Boot

The updated `setup_bookworm.sh` now automatically enables services. If you already ran the old setup, enable them manually:

```bash
# Enable Ollama to start on boot
sudo systemctl enable ollama

# Enable Pi Assistant to start on boot
sudo systemctl enable pi-assistant

# Check status
sudo systemctl status ollama
sudo systemctl status pi-assistant
```

### 3. Reboot

```bash
sudo reboot
```

After reboot, everything should:
- ✅ Start automatically
- ✅ Camera should be smooth
- ✅ Access at `http://PI_IP:8080`

---

## 🔍 Verify Everything Works

After reboot, check services:

```bash
# Check Pi Assistant status
sudo systemctl status pi-assistant

# Check Ollama status
sudo systemctl status ollama

# View live logs
sudo journalctl -u pi-assistant -f

# Check if services are enabled
sudo systemctl is-enabled pi-assistant
sudo systemctl is-enabled ollama
```

---

## 🎯 What Changed in `setup_bookworm.sh`

1. **Removed:** Virtual camera setup (`v4l2loopback`)
2. **Added:** Automatic systemd service enablement
3. **Updated:** Step numbers (9 steps instead of 10)
4. **Improved:** Final instructions for auto-start

---

## 📱 Service Management Commands

```bash
# Status
sudo systemctl status pi-assistant

# Start
sudo systemctl start pi-assistant

# Stop
sudo systemctl stop pi-assistant

# Restart
sudo systemctl restart pi-assistant

# View logs
sudo journalctl -u pi-assistant -f

# Enable auto-start (if not already)
sudo systemctl enable pi-assistant

# Disable auto-start
sudo systemctl disable pi-assistant
```

---

## 🚀 Fresh Deployment (Updated)

If you want to deploy to a **new Pi** from scratch:

```bash
cd ~/workspace
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me

# Run updated setup (no virtual camera, auto-start enabled)
chmod +x setup_bookworm.sh
./setup_bookworm.sh

# Reboot to start services
sudo reboot
```

After reboot:
- Ollama will start automatically
- Pi Assistant will start automatically
- Access at `http://PI_IP:8080`

---

## ✨ Benefits

- **No more choppy camera** - removed virtual camera overhead
- **Auto-start on boot** - no manual startup needed
- **Cleaner setup** - one less dependency
- **Better performance** - direct camera access

---

## 🐛 Troubleshooting

### Camera still choppy?
```bash
# Check camera
rpicam-hello --list-cameras

# Test camera capture
rpicam-still -o test.jpg

# Check for virtual camera remnants
lsmod | grep v4l2loopback  # Should show nothing
ls /dev/video*  # Should not show /dev/video10
```

### Services not starting?
```bash
# Check service files exist
ls -la /etc/systemd/system/pi-assistant.service
ls -la /etc/systemd/system/ollama.service

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable ollama pi-assistant
sudo systemctl start ollama pi-assistant
```

### Port conflicts?
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Kill if needed
sudo systemctl stop pi-assistant
```
