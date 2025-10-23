# 🍓 Raspberry Pi Quick Reference Card

**Dutch Learning AI Assistant - Essential Commands**

---

## 🚀 Setup (First Time Only)

```bash
cd ~/workspace/speak-dutch-to-me
./setup_raspberry_pi.sh
sudo reboot
```

---

## ▶️ Start/Stop

### Manual
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
./start_assistant.sh                    # Start
# Press Ctrl+C to stop
```

### Service (if enabled)
```bash
sudo systemctl start pi-assistant       # Start
sudo systemctl stop pi-assistant        # Stop
sudo systemctl restart pi-assistant     # Restart
```

---

## 🌐 Access

| Service | URL |
|---------|-----|
| Main | `http://<pi-ip>:8080` |
| Dutch Learning | `http://<pi-ip>:8080/dutch` |
| Ollama | `http://localhost:11434` |

Get IP: `hostname -I`

---

## 📝 Logs

```bash
# App logs
tail -f ~/workspace/speak-dutch-to-me/pi-assistant/logs/assistant.log

# Service logs
sudo journalctl -u pi-assistant -f
```

---

## 🔧 Config

```bash
nano ~/workspace/speak-dutch-to-me/pi-assistant/.env
```

---

## 📷 Camera

```bash
rpicam-hello                            # Test
v4l2-ctl --list-devices                 # List devices
ffplay /dev/video10                     # View virtual cam
```

---

## 🎤 Audio

```bash
arecord -l                              # List input devices
aplay -l                                # List output devices
systemctl --user restart pulseaudio     # Restart audio
```

---

## 🤖 Ollama

```bash
ollama list                             # List models
ollama run llama3.2:3b                  # Test chat
curl http://localhost:11434/api/version # Check status
```

---

## 🆘 Quick Fixes

### Won't start?
```bash
sudo lsof -i :8080                      # Check port
cd ~/workspace/speak-dutch-to-me/pi-assistant
source venv/bin/activate
python main.py                          # Run directly
```

### Camera not working?
```bash
vcgencmd get_camera                     # Check camera
sudo usermod -a -G video $USER          # Add permissions
# Log out and back in
```

### Out of memory?
```bash
free -h                                 # Check memory
ollama pull llama3.2:1b                # Use smaller model
```

---

## 📊 Status Check

```bash
sudo systemctl status pi-assistant      # App status
sudo systemctl status ollama            # Ollama status
htop                                    # System resources
df -h                                   # Disk space
```

---

## 🔄 Update

```bash
cd ~/workspace/speak-dutch-to-me
git pull
cd pi-assistant
source venv/bin/activate
pip install -r requirements.txt --upgrade
sudo systemctl restart pi-assistant     # If using service
```

---

## 📚 Full Guides

- **Setup:** [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)
- **Quick Start:** [QUICK_START.md](QUICK_START.md)
- **Main README:** [README.md](README.md)

---

**Happy Learning! 🇳🇱**
