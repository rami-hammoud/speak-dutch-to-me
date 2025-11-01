# 🚀 Immediate Actions for Your Pi

## Current Situation
✅ You ran the setup script  
✅ You rebooted  
✅ UI is accessible  
❌ Camera is choppy (virtual camera issue)  
❌ Services don't start automatically  

---

## 🔥 Fix It Now (Run on Your Pi)

### Step 1: Pull Latest Changes

```bash
cd ~/workspace/speak-dutch-to-me
git pull origin main
```

### Step 2: Remove Virtual Camera (Fix Choppy Camera)

```bash
# Quick cleanup
./cleanup_virtual_camera.sh

# Or manually:
sudo modprobe -r v4l2loopback
sudo rm -f /etc/modules-load.d/v4l2loopback.conf
sudo rm -f /etc/modprobe.d/v4l2loopback.conf
```

### Step 3: Enable Auto-Start Services

```bash
# Enable both services
sudo systemctl enable ollama
sudo systemctl enable pi-assistant

# Verify they're enabled
sudo systemctl is-enabled ollama
sudo systemctl is-enabled pi-assistant
```

### Step 4: Reboot

```bash
sudo reboot
```

---

## ✅ After Reboot

Everything should:
- Start automatically (no manual start needed)
- Camera should be smooth
- Access at `http://PI_IP:8080`

### Verify:

```bash
# Check services are running
sudo systemctl status ollama
sudo systemctl status pi-assistant

# View logs
sudo journalctl -u pi-assistant -f

# Test camera
rpicam-still -o test.jpg
```

---

## 📋 Updated Setup for Fresh Pi

If you want to **re-deploy from scratch** on a fresh Pi (or another Pi):

```bash
cd ~/workspace
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me

# Run the updated setup
chmod +x setup_bookworm.sh
./setup_bookworm.sh

# Reboot
sudo reboot
```

**Changes in updated script:**
- ❌ No virtual camera (removed)
- ✅ Auto-start enabled by default
- ✅ 9 steps instead of 10
- ✅ Better camera performance

---

## 🎯 Service Management

```bash
# Status
sudo systemctl status pi-assistant

# Logs (live)
sudo journalctl -u pi-assistant -f

# Restart
sudo systemctl restart pi-assistant

# Stop
sudo systemctl stop pi-assistant

# Start
sudo systemctl start pi-assistant
```

---

## 🐛 Troubleshooting

### Camera still choppy?
```bash
# Check for v4l2loopback
lsmod | grep v4l2loopback  # Should show nothing

# List video devices
ls /dev/video*  # Should NOT have /dev/video10

# Test camera
rpicam-hello --list-cameras
rpicam-still -o test.jpg
```

### Service not starting?
```bash
# Check service file
cat /etc/systemd/system/pi-assistant.service

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable pi-assistant
sudo systemctl start pi-assistant

# Check logs for errors
sudo journalctl -u pi-assistant -n 50
```

### Port 8080 in use?
```bash
# See what's using it
sudo lsof -i :8080

# Kill old process
sudo systemctl stop pi-assistant
sudo pkill -f "python.*main.py"
```

---

## 📝 What We Fixed

1. **Removed v4l2loopback** - Was causing choppy camera performance due to extra processing overhead
2. **Enabled systemd auto-start** - Services now start automatically on boot
3. **Updated setup script** - `setup_bookworm.sh` now configures everything correctly
4. **Better documentation** - Clear instructions for management

---

## 🎉 Expected Result

After these fixes:
- ⚡ Smooth camera performance
- 🔄 Auto-start on boot
- 📊 Easy service management with systemd
- 🚀 Production-ready deployment
