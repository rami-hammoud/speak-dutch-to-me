# Pi Assistant - Management Scripts

Quick reference for managing the Dutch Learning AI Assistant.

## 🚀 Start / Stop / Status

### Start the Assistant
```bash
cd pi-assistant
./start_assistant.sh
```

**Features:**
- ✅ Automatically checks if port is already in use
- ✅ Offers to kill existing instances
- ✅ Creates `.env` from template if missing
- ✅ Shows access URLs when started
- ✅ Logs output to `logs/assistant.log`

### Stop the Assistant
```bash
cd pi-assistant
./stop_assistant.sh
```

**Features:**
- ✅ Graceful shutdown (SIGTERM first)
- ✅ Force kill if needed (SIGKILL after 5 seconds)
- ✅ Finds processes by port and name
- ✅ Confirms before killing

### Check Status
```bash
cd pi-assistant
./status_assistant.sh
```

**Shows:**
- ✅ Virtual environment status
- ✅ Configuration file status
- ✅ Process running status (PID, uptime)
- ✅ Web interface accessibility
- ✅ Ollama service status
- ✅ Virtual camera status
- ✅ Recent log errors
- ✅ Systemd service status

## 🔧 Common Issues & Solutions

### Issue: "Port 8080 already in use"

**Solution 1: Let start script handle it**
```bash
./start_assistant.sh
# It will prompt you to kill the existing process
```

**Solution 2: Manual stop**
```bash
./stop_assistant.sh
./start_assistant.sh
```

**Solution 3: Change port**
```bash
nano .env
# Change: PORT=8081
./start_assistant.sh
```

**Solution 4: Find and kill manually**
```bash
# Find the process
lsof -i :8080
# or
ps aux | grep main.py

# Kill it
kill <PID>
# or force kill
kill -9 <PID>
```

### Issue: ".env file not found"

**Solution:**
```bash
cd pi-assistant

# Option 1: Auto-create (start script does this)
./start_assistant.sh

# Option 2: Manual copy
cp .env.example .env
nano .env  # Edit settings
./start_assistant.sh
```

### Issue: "Virtual environment not found"

**Solution:**
```bash
cd ..
./setup_trixie.sh  # Re-run setup
```

### Issue: Can't access web interface

**Check status:**
```bash
./status_assistant.sh
```

**Verify it's running:**
```bash
curl http://localhost:8080
```

**Check logs:**
```bash
tail -f logs/assistant.log
```

**Restart:**
```bash
./stop_assistant.sh
./start_assistant.sh
```

## 📋 Useful Commands

### View Real-time Logs
```bash
tail -f logs/assistant.log
```

### View Only Errors
```bash
grep -i error logs/assistant.log
```

### Check Ollama
```bash
ollama list
ollama ps
curl http://localhost:11434/api/version
```

### Test Virtual Camera
```bash
ls -l /dev/video*
v4l2-ctl --list-devices
```

### Systemd Service (if installed)
```bash
# Start
sudo systemctl start pi-assistant

# Stop
sudo systemctl stop pi-assistant

# Status
sudo systemctl status pi-assistant

# Enable on boot
sudo systemctl enable pi-assistant

# Disable on boot
sudo systemctl disable pi-assistant

# View logs
sudo journalctl -u pi-assistant -f
```

## 🔄 Restart After Changes

If you modify code or configuration:

```bash
./stop_assistant.sh
./start_assistant.sh
```

Or if using systemd:
```bash
sudo systemctl restart pi-assistant
```

## 🧹 Cleanup / Fresh Start

### Remove virtual environment and reinstall
```bash
cd pi-assistant
rm -rf venv
cd ..
./setup_trixie.sh
```

### Clean logs
```bash
cd pi-assistant
rm -f logs/*.log
mkdir -p logs
```

### Reset configuration
```bash
cd pi-assistant
rm .env
cp .env.example .env
nano .env  # Edit as needed
```

## 🌐 Access URLs

After starting, access at:
- **Main interface:** `http://YOUR_PI_IP:8080`
- **Dutch learning:** `http://YOUR_PI_IP:8080/dutch-learning`
- **API docs:** `http://YOUR_PI_IP:8080/docs`
- **MCP Server:** `http://YOUR_PI_IP:8081` (if enabled)

Replace `YOUR_PI_IP` with your Pi's IP address (shown when starting).

## 💡 Pro Tips

### Run in Background
```bash
cd pi-assistant
nohup ./start_assistant.sh > /dev/null 2>&1 &
```

### Auto-restart on Crash
Use systemd service for automatic restart on failure.

### Multiple Instances
Change port in `.env` to run multiple instances:
```bash
# Instance 1: PORT=8080
# Instance 2: PORT=8081
# etc.
```

### Remote Access
```bash
# From another machine
ssh pi@YOUR_PI_IP
cd workspace/speak-dutch-to-me/pi-assistant
./status_assistant.sh
```

## 🆘 Emergency Stop

If nothing else works:
```bash
# Kill all Python processes (use with caution!)
pkill -9 python

# Or kill by name
pkill -9 -f main.py

# Or kill by port
kill -9 $(lsof -t -i:8080)
```

## 📊 Performance Monitoring

### Check CPU/Memory Usage
```bash
# While running
ps aux | grep python
top -p $(pgrep -f main.py)

# Or use htop
htop
```

### Check Disk Space
```bash
df -h
du -sh pi-assistant/logs/
```

### Monitor Network
```bash
netstat -tlnp | grep 8080
ss -tlnp | grep 8080
```
