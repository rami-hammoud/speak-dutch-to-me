# 🚀 Deployment Checklist - Fresh Raspberry Pi

## Pre-Deployment
- [ ] Fresh Raspberry Pi 5 running Debian Trixie
- [ ] Internet connection active
- [ ] SSH access configured (if deploying remotely)
- [ ] Camera module connected (IMX500/Pi Camera)
- [ ] ReSpeaker 4-mic array connected
- [ ] GitHub credentials configured

## Deployment Steps

### 1. System Preparation
```bash
sudo apt update && sudo apt upgrade -y
cd ~
mkdir -p workspace
cd workspace
```
- [ ] System updated
- [ ] Workspace directory created

### 2. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me
```
- [ ] Repository cloned
- [ ] In correct directory

### 3. Run Setup Script
```bash
chmod +x setup_trixie.sh
./setup_trixie.sh
```

**Setup will install:**
- [ ] Python 3.13+ environment
- [ ] System dependencies
- [ ] Camera drivers (libcamera, picamera2)
- [ ] Audio system (ALSA, PulseAudio)
- [ ] Ollama + llama3.2:3b model
- [ ] Virtual camera (v4l2loopback)
- [ ] Python packages
- [ ] Database initialization

**Duration:** ~15-30 minutes depending on internet speed

### 4. Configuration
```bash
cd pi-assistant
nano .env
```

**Configure (optional):**
- [ ] OPENAI_API_KEY (if using GPT-4)
- [ ] ANTHROPIC_API_KEY (if using Claude)
- [ ] BRAVE_SEARCH_API_KEY (for web search)
- [ ] Other API keys as needed

**Note:** Works offline with Ollama even without API keys!

### 5. Start Application
```bash
./start_assistant.sh
```
- [ ] Application started without errors
- [ ] Web interface accessible
- [ ] Port 8080 is responding

### 6. Verification
```bash
./status_assistant.sh
```

**Check:**
- [ ] Pi Assistant is RUNNING
- [ ] Web interface accessible
- [ ] Ollama service active
- [ ] Camera detected
- [ ] Audio devices detected

### 7. Test Features
**Open browser:** `http://YOUR_PI_IP:8080`

- [ ] Main dashboard loads
- [ ] Dutch learning interface accessible
- [ ] Chat functionality works
- [ ] Camera capture works (if camera connected)
- [ ] Ollama responds to queries

### 8. Optional - Auto-Start Setup
```bash
# If you want it to start on boot
sudo systemctl enable pi-assistant
sudo systemctl status pi-assistant
```
- [ ] Systemd service enabled
- [ ] Service starts on boot

### 9. Optional - Reboot Test
```bash
sudo reboot
# Wait for reboot
./status_assistant.sh
```
- [ ] System boots successfully
- [ ] Virtual camera loaded (/dev/video10)
- [ ] Services start automatically (if enabled)

## Post-Deployment

### Access URLs
- **Main Dashboard:** http://YOUR_PI_IP:8080
- **Dutch Learning:** http://YOUR_PI_IP:8080/dutch-learning
- **API Docs:** http://YOUR_PI_IP:8080/docs
- **MCP Server:** http://YOUR_PI_IP:8081 (if enabled)

### Management Commands
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Start
./start_assistant.sh

# Stop
./stop_assistant.sh

# Check status
./status_assistant.sh

# View logs
tail -f logs/assistant.log
```

### Verification Script
```bash
cd ~/workspace/speak-dutch-to-me
./verify_installation.sh
```

## Troubleshooting

### Issue: Port 8080 already in use
```bash
cd pi-assistant
./stop_assistant.sh
./start_assistant.sh
```

### Issue: Camera not working
```bash
# Check camera
rpicam-hello --list-cameras
v4l2-ctl --list-devices

# Check logs
tail -f logs/assistant.log | grep -i camera
```

### Issue: Ollama not responding
```bash
sudo systemctl restart ollama
curl http://localhost:11434/api/version
```

### Issue: Virtual environment missing
```bash
cd ~/workspace/speak-dutch-to-me
./setup_trixie.sh  # Re-run setup
```

## Success Criteria

Your deployment is successful when:
- ✅ `./status_assistant.sh` shows "Pi Assistant is RUNNING"
- ✅ Web interface loads at http://YOUR_PI_IP:8080
- ✅ Can send chat messages and get AI responses
- ✅ Ollama responds: `curl http://localhost:11434/api/version`
- ✅ No errors in logs: `tail -f logs/assistant.log`

## Next Steps

Once deployed and verified:
1. [ ] Test Dutch learning features
2. [ ] Test camera functionality
3. [ ] Test audio input/output
4. [ ] Configure any API keys needed
5. [ ] Ready to build Personal Assistant Agent! 🎉

## Notes

**Deployment Date:** _______________

**Pi IP Address:** _______________

**Issues Encountered:**
- 
- 
- 

**Resolution:**
- 
- 
- 

**Performance Notes:**
- 
- 
- 

---

## Quick Reference

```bash
# Full deployment (one command)
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/speak-dutch-to-me/main/setup_trixie.sh | bash

# Or manual
git clone https://github.com/YOUR_USERNAME/speak-dutch-to-me.git
cd speak-dutch-to-me
./setup_trixie.sh

# Start/Stop/Status
cd pi-assistant
./start_assistant.sh
./stop_assistant.sh
./status_assistant.sh

# Logs
tail -f logs/assistant.log
```
