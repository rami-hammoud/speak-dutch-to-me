# 🚀 Raspberry Pi Deployment Checklist

Use this checklist when setting up your Dutch Learning AI Assistant on a new Raspberry Pi.

## Before You Begin

### Hardware Requirements
- [ ] Raspberry Pi 4 (4GB+) or Pi 5
- [ ] Power supply (5V 3A minimum, official recommended)
- [ ] MicroSD card (32GB minimum, 64GB+ recommended)
- [ ] Ethernet cable or WiFi configured
- [ ] HDMI cable and monitor (for initial setup)
- [ ] Keyboard and mouse (for initial setup)

### Optional Hardware
- [ ] AI HAT+ camera module
- [ ] ReSpeaker microphone array
- [ ] Cooling fan or heatsink
- [ ] Case with ventilation

### Prerequisites
- [ ] Raspberry Pi OS (64-bit, Bookworm or later) installed
- [ ] SSH enabled (for remote setup)
- [ ] Internet connection active
- [ ] Know your Pi's IP address: `hostname -I`

## Setup Process

### Phase 1: Initial System Setup (15 minutes)

- [ ] **Boot up the Pi**
  ```bash
  # Connect via SSH or use monitor/keyboard
  ssh pi@<raspberry-pi-ip>
  ```

- [ ] **Update system** (done by setup script, but good to do first)
  ```bash
  sudo apt update
  sudo apt upgrade -y
  ```

- [ ] **Create workspace directory**
  ```bash
  mkdir -p ~/workspace
  cd ~/workspace
  ```

- [ ] **Clone repository**
  ```bash
  git clone <your-repo-url> speak-dutch-to-me
  cd speak-dutch-to-me
  ```

### Phase 2: Run Setup Script (30-60 minutes)

- [ ] **Make script executable**
  ```bash
  chmod +x setup_raspberry_pi.sh
  ```

- [ ] **Run the setup script**
  ```bash
  ./setup_raspberry_pi.sh
  ```
  
  The script will:
  - ✅ Update system packages
  - ✅ Install dependencies
  - ✅ Setup camera and audio
  - ✅ Install Ollama + llama3.2:3b
  - ✅ Create Python virtual environment
  - ✅ Initialize database
  - ✅ Generate configuration files
  - ✅ Optionally create systemd services

- [ ] **Review setup output**
  - Check for any errors or warnings
  - Note the Pi's IP address shown

- [ ] **Reboot the system**
  ```bash
  sudo reboot
  ```

### Phase 3: Configuration (10 minutes)

- [ ] **SSH back into the Pi** (after reboot)
  ```bash
  ssh pi@<raspberry-pi-ip>
  ```

- [ ] **Navigate to project**
  ```bash
  cd ~/workspace/speak-dutch-to-me/pi-assistant
  ```

- [ ] **Edit configuration**
  ```bash
  nano .env
  ```

- [ ] **Add API keys** (optional, works without them)
  ```
  OPENAI_API_KEY=sk-...
  ANTHROPIC_API_KEY=sk-ant-...
  BRAVE_SEARCH_API_KEY=...
  ```

- [ ] **Save and close** (`Ctrl+X`, then `Y`, then `Enter`)

### Phase 4: Testing (15 minutes)

- [ ] **Test Ollama**
  ```bash
  curl http://localhost:11434/api/version
  ollama list
  ```
  Expected: Should show llama3.2:3b model

- [ ] **Test camera** (if connected)
  ```bash
  rpicam-hello
  rpicam-still -o test.jpg
  ```
  Expected: Camera preview and test photo

- [ ] **Test virtual camera**
  ```bash
  v4l2-ctl --list-devices
  ```
  Expected: Should see "PiAssistantCam" at /dev/video10

- [ ] **Test audio input** (if microphone connected)
  ```bash
  arecord -l
  arecord -d 3 test.wav
  aplay test.wav
  ```
  Expected: Should record and play back audio

- [ ] **Start the assistant**
  ```bash
  ./start_assistant.sh
  ```
  Expected: Server starts on port 8080

- [ ] **Test web interface**
  - Open browser: `http://<pi-ip>:8080`
  - Expected: Should see main dashboard

- [ ] **Test Dutch learning page**
  - Navigate to: `http://<pi-ip>:8080/dutch`
  - Expected: Should see flashcards and vocabulary

- [ ] **Stop the assistant** (`Ctrl+C`)

### Phase 5: Production Setup (Optional, 10 minutes)

If you want the assistant to auto-start on boot:

- [ ] **Enable systemd service**
  ```bash
  sudo systemctl enable pi-assistant
  sudo systemctl start pi-assistant
  ```

- [ ] **Check service status**
  ```bash
  sudo systemctl status pi-assistant
  ```
  Expected: "active (running)" status

- [ ] **Test auto-start**
  ```bash
  sudo reboot
  # Wait for reboot, then check
  sudo systemctl status pi-assistant
  ```

- [ ] **Enable virtual camera service** (optional)
  ```bash
  sudo systemctl enable virtual-camera
  sudo systemctl start virtual-camera
  ```

### Phase 6: Security Hardening (Optional, 15 minutes)

- [ ] **Change default password**
  ```bash
  passwd
  ```

- [ ] **Setup firewall**
  ```bash
  sudo apt install ufw
  sudo ufw allow 22/tcp     # SSH
  sudo ufw allow 8080/tcp   # Web interface
  sudo ufw enable
  ```

- [ ] **Secure .env file**
  ```bash
  chmod 600 ~/workspace/speak-dutch-to-me/pi-assistant/.env
  ```

- [ ] **Setup automatic updates** (careful with auto-reboot)
  ```bash
  sudo apt install unattended-upgrades
  sudo dpkg-reconfigure -plow unattended-upgrades
  ```

- [ ] **Consider reverse proxy** (for internet access)
  - Install nginx or caddy
  - Setup HTTPS with Let's Encrypt
  - Add authentication

## Verification Checklist

After setup, verify everything works:

### System
- [ ] Pi boots successfully
- [ ] Network connection stable
- [ ] Sufficient disk space: `df -h` (at least 10GB free)
- [ ] Memory usage reasonable: `free -h`

### Services
- [ ] Ollama running: `sudo systemctl status ollama`
- [ ] Pi Assistant running: `sudo systemctl status pi-assistant` (if enabled)
- [ ] Virtual camera loaded: `lsmod | grep v4l2loopback`

### Features
- [ ] Web interface accessible from browser
- [ ] Dutch learning page loads correctly
- [ ] Vocabulary flashcards appear
- [ ] Camera feed works (if hardware present)
- [ ] Audio recording works (if microphone present)
- [ ] Ollama responds to queries

### Performance
- [ ] CPU temperature < 70°C: `vcgencmd measure_temp`
- [ ] No throttling: `vcgencmd get_throttled` (should be 0x0)
- [ ] Response time acceptable for LLM queries

## Post-Setup Tasks

### Daily Use
- [ ] Bookmark web interface on your devices
- [ ] Test different features (vocabulary, grammar, pronunciation)
- [ ] Set learning goals in the app
- [ ] Try voice commands (when implemented)

### Maintenance
- [ ] Check logs regularly: `tail -f ~/workspace/speak-dutch-to-me/pi-assistant/logs/assistant.log`
- [ ] Monitor disk space weekly
- [ ] Update system monthly: `sudo apt update && sudo apt upgrade`
- [ ] Backup database monthly: `cp ~/workspace/speak-dutch-to-me/pi-assistant/data/dutch_vocab.db ~/backup/`

### Optimization
- [ ] Adjust camera settings if needed (in .env)
- [ ] Try different Ollama models for better/faster responses
- [ ] Configure audio levels for optimal recognition
- [ ] Fine-tune Dutch learning difficulty

## Troubleshooting Reference

If something goes wrong, check:

1. **Logs**
   - Application: `~/workspace/speak-dutch-to-me/pi-assistant/logs/`
   - Service: `sudo journalctl -u pi-assistant -f`
   - System: `sudo dmesg | tail`

2. **Common Issues**
   - Port 8080 in use: `sudo lsof -i :8080`
   - Camera not detected: `vcgencmd get_camera`
   - Ollama not responding: `sudo systemctl restart ollama`
   - Out of memory: Check `free -h`, restart Pi

3. **Quick Fixes**
   - Restart service: `sudo systemctl restart pi-assistant`
   - Restart Pi: `sudo reboot`
   - Reinstall dependencies: See RASPBERRY_PI_SETUP.md

## Success Criteria

Your setup is successful when:

✅ You can access the web interface from any device on your network  
✅ The Dutch learning page shows vocabulary and exercises  
✅ Ollama responds to queries (test in /dutch page)  
✅ Camera works (if connected)  
✅ Audio works (if microphone connected)  
✅ System is stable and responsive  
✅ Services auto-start after reboot (if configured)  

## Next Steps

After successful setup:

1. **Learn Dutch!** 🇳🇱
   - Start with vocabulary flashcards
   - Try pronunciation practice
   - Complete daily challenges

2. **Customize**
   - Add your own vocabulary
   - Adjust learning pace
   - Configure personal preferences

3. **Extend**
   - Add e-commerce agent features
   - Setup personal assistant integrations
   - Connect smart home devices

4. **Share**
   - Let others on your network use it
   - Get feedback
   - Contribute improvements

## Useful Links

- **Quick Reference:** [PI_QUICK_REF.md](PI_QUICK_REF.md)
- **Full Setup Guide:** [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)
- **Main README:** [README.md](README.md)
- **Project Documentation:** [pi-assistant/README.md](pi-assistant/README.md)

---

**Estimated Total Time:** 1.5 - 2 hours (mostly waiting for downloads)

**Difficulty Level:** Intermediate (basic Linux/Pi knowledge helpful)

**Support:** Check logs first, then refer to troubleshooting guides

---

**Happy Setting Up! 🚀🇳🇱**
