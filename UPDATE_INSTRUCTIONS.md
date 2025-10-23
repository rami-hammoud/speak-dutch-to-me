# 🚀 Quick Update Instructions for Your Raspberry Pi

## Current Status
You ran `setup_trixie.sh` successfully, but encountered the "Address already in use" error when starting.

## What Was Fixed (in this update)
✅ Port conflict detection & resolution
✅ Auto .env file creation  
✅ Better process management
✅ Stop/Status scripts added

## Update Your Pi (Run These Commands)

### 1. Pull the latest changes
```bash
cd ~/workspace/speak-dutch-to-me
git pull
```

### 2. Stop any running instance
```bash
cd pi-assistant

# New stop script (graceful shutdown)
./stop_assistant.sh

# Or manually kill if needed
pkill -f main.py
# or
kill $(lsof -t -i:8080)
```

### 3. Start with the improved script
```bash
./start_assistant.sh
```

The new start script will:
- ✅ Auto-detect if port 8080 is in use
- ✅ Offer to kill the old process
- ✅ Create .env from template if missing
- ✅ Show you the access URLs

### 4. Verify it's working
```bash
./status_assistant.sh
```

## New Commands Available

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Start (with smart port detection)
./start_assistant.sh

# Stop (graceful shutdown)
./stop_assistant.sh

# Check status (detailed info)
./status_assistant.sh

# View logs
tail -f logs/assistant.log
```

## Expected Output

When you run `./start_assistant.sh`, you should now see:

```
[INFO] Activating virtual environment...
[INFO] Starting Pi Assistant...
[SUCCESS] Web interface will be available at:
  • http://10.0.0.51:8080
  • http://10.0.0.51:8080/dutch-learning
  • http://localhost:8080

[INFO] Press Ctrl+C to stop the assistant
```

If port is in use, you'll see:
```
[WARNING] Port 8080 is already in use!

Process using port 8080:
  PID: 12345
  Command: python

Kill existing process and restart? [Y/n]:
```

Just press `y` and it will handle everything!

## Troubleshooting

### If you still see "Address already in use"

```bash
# Use the new stop script
cd pi-assistant
./stop_assistant.sh

# Then start again
./start_assistant.sh
```

### If .env is still missing

```bash
cd pi-assistant
cp .env.example .env
./start_assistant.sh
```

### For a complete fresh start

```bash
cd ~/workspace/speak-dutch-to-me
rm -rf pi-assistant/venv
./setup_trixie.sh
```

## Files Updated in This Batch

- `pi-assistant/start_assistant.sh` ⚡ Enhanced with port detection
- `pi-assistant/stop_assistant.sh` ✨ New graceful stop script
- `pi-assistant/status_assistant.sh` ✨ New comprehensive status check
- `pi-assistant/.env.example` ✨ New configuration template
- `pi-assistant/MANAGEMENT.md` 📚 New management guide
- `setup_trixie.sh` 🔧 Now creates .env automatically

## After Update, Test These

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# 1. Check status
./status_assistant.sh

# 2. If running, stop it
./stop_assistant.sh

# 3. Start fresh
./start_assistant.sh

# 4. Access the web interface
# Open browser: http://YOUR_PI_IP:8080
```

## Success Indicators

✅ No "Address already in use" error
✅ No ".env file not found" error
✅ Web interface loads successfully
✅ `status_assistant.sh` shows "Pi Assistant is RUNNING"

---

**That's it! Pull the changes and try starting again. The new scripts will handle the port conflict automatically.** 🎉
