# 🚀 Development Workflow Guide

## Overview
This guide helps you develop and improve the Dutch Learning AI Assistant efficiently.

## Development Setup

### 1. Development Environment

You have two options:

**Option A: Develop on Pi (Direct)**
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
# Edit files directly
nano main.py
# Test immediately
./stop_assistant.sh && ./start_assistant.sh
```

**Option B: Develop on Your Mac, Deploy to Pi**
```bash
# On Mac: Edit files locally
cd /Users/rami/workspace/speak-dutch-to-me
# Edit in VS Code or your preferred editor

# Commit and push
git add -A
git commit -m "Your changes"
git push origin main

# On Pi: Pull and restart
cd ~/workspace/speak-dutch-to-me
git pull
cd pi-assistant
./stop_assistant.sh && ./start_assistant.sh
```

## Quick Development Cycle

### Fast Iteration Loop
```bash
# On Pi
cd ~/workspace/speak-dutch-to-me/pi-assistant

# 1. Edit code
nano main.py  # or templates/index.html, etc.

# 2. Restart to test changes
./stop_assistant.sh && ./start_assistant.sh

# 3. Check logs for errors
tail -f logs/assistant.log

# 4. Test in browser
# Open: http://YOUR_PI_IP:8080
```

### Auto-Reload for Development

Enable auto-reload in uvicorn (already configured):
```python
# In main.py, uvicorn runs with reload=True in DEBUG mode
# Any file changes will auto-restart the server
```

## Project Structure

```
pi-assistant/
├── main.py                 # FastAPI app, routes, WebSocket
├── ai_service.py          # AI/LLM integration (Ollama, OpenAI)
├── config.py              # Configuration management
├── load_seed_data.py      # Database seeding
│
├── mcp/                   # Model Context Protocol server
│   ├── __init__.py
│   └── server.py          # MCP tools (camera, GPIO, etc.)
│
├── ui/                    # Hardware managers
│   ├── __init__.py
│   ├── camera_manager.py  # Camera operations
│   └── audio_manager.py   # Audio I/O
│
├── templates/             # HTML templates
│   ├── index.html         # Main dashboard
│   └── dutch_learning.html # Dutch learning interface
│
├── static/                # Static assets
│   └── style.css          # Shared styles
│
├── data/                  # Database and data files
│   └── dutch_vocab.db     # SQLite database
│
└── logs/                  # Application logs
    └── assistant.log
```

## Development Tasks

### Task 1: Fix Camera Command ✅
**Status: DONE**
- Updated `mcp/server.py` to use `rpicam-still` instead of `libcamera-still`
- Added fallback to `libcamera-still` for older systems

### Task 2: Improve UI Design
**Files to edit:**
- `templates/index.html` - Main dashboard
- `templates/dutch_learning.html` - Dutch learning page
- `static/style.css` - Shared styles

**Goals:**
- Modern, professional design
- Better mobile responsiveness
- Improved camera preview
- Better error handling and feedback
- Loading states and animations

### Task 3: Add Features
**Ideas:**
- Voice input for Dutch practice
- Vocabulary progress tracking
- Image recognition for vocabulary
- Grammar explanations
- Pronunciation feedback
- Flashcard system

## Common Development Tasks

### Modify the UI

**Edit HTML Template:**
```bash
cd pi-assistant/templates
nano index.html

# Then restart
cd ..
./stop_assistant.sh && ./start_assistant.sh
```

**Add CSS Styles:**
```bash
cd pi-assistant/static
nano style.css
# Changes reflect immediately (no restart needed for CSS)
```

### Add a New API Endpoint

**In `main.py`:**
```python
@assistant.app.post("/api/your-endpoint")
async def your_endpoint(data: dict):
    try:
        # Your logic here
        return {"success": True, "data": result}
    except Exception as e:
        return {"success": False, "error": str(e)}
```

### Add a New MCP Tool

**In `mcp/server.py`:**
```python
# 1. Define the tool
@self.server.call_tool()
async def your_tool_name(arguments: dict) -> list[types.TextContent]:
    result = await self._your_tool_implementation(arguments)
    return [types.TextContent(type="text", text=json.dumps(result))]

# 2. Implement the function
async def _your_tool_implementation(self, args: Dict[str, Any]) -> Dict[str, Any]:
    try:
        # Your implementation
        return {"success": True, "result": data}
    except Exception as e:
        return {"error": str(e)}
```

### Modify AI Behavior

**Edit `ai_service.py`:**
```python
# Change system prompts
# Modify temperature/parameters
# Add new AI providers
```

## Testing

### Manual Testing
```bash
# 1. Start the assistant
./start_assistant.sh

# 2. Open browser
http://YOUR_PI_IP:8080

# 3. Test features
# - Click buttons
# - Check camera
# - Try voice input
# - Test Dutch learning

# 4. Check logs for errors
tail -f logs/assistant.log
```

### Check Specific Components
```bash
# Test Ollama
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello"
}'

# Test camera
rpicam-still -o test.jpg

# Test audio
arecord -l
aplay -l
```

## Debugging

### View Logs
```bash
# Real-time logs
tail -f logs/assistant.log

# Filter for errors
grep -i error logs/assistant.log

# Last 100 lines
tail -100 logs/assistant.log
```

### Check Server Status
```bash
./status_assistant.sh
```

### Python Debugging
```python
# Add debug prints
print(f"DEBUG: variable = {variable}")

# Or use logging
import logging
logging.info(f"Info message: {data}")
logging.error(f"Error: {error}")
```

### Browser DevTools
```
F12 or Right-click > Inspect
- Console: See JavaScript errors
- Network: Check API calls
- Application: Check WebSocket connections
```

## Git Workflow

### Make Changes
```bash
# On Mac (edit locally)
cd /Users/rami/workspace/speak-dutch-to-me

# 1. Create a feature branch (optional but recommended)
git checkout -b feature/ui-improvements

# 2. Make your changes
# Edit files...

# 3. Test locally if possible, or commit and test on Pi

# 4. Commit
git add -A
git commit -m "feat: improve UI design with modern styling"

# 5. Push
git push origin feature/ui-improvements

# 6. On Pi: pull and test
cd ~/workspace/speak-dutch-to-me
git fetch
git checkout feature/ui-improvements
git pull
cd pi-assistant
./stop_assistant.sh && ./start_assistant.sh
```

### Quick Updates (Small Changes)
```bash
# On Mac
git add -A
git commit -m "fix: camera command for newer Pi OS"
git push

# On Pi
git pull
cd pi-assistant
./stop_assistant.sh && ./start_assistant.sh
```

## Performance Tips

### Development Mode
```bash
# In .env, enable debug mode
DEBUG=true
```

### Production Mode
```bash
# In .env
DEBUG=false

# Use systemd service for auto-restart
sudo systemctl enable pi-assistant
sudo systemctl start pi-assistant
```

## Next Steps

1. **Fix Camera** ✅ - DONE (updated mcp/server.py)

2. **Improve UI** - Let's do this next!
   - Modern design
   - Better responsiveness
   - Professional styling

3. **Add Features**
   - Voice input
   - Progress tracking
   - Better error handling

4. **Testing**
   - Test on actual Pi
   - Mobile testing
   - Different browsers

## Quick Reference Commands

```bash
# Development cycle
cd ~/workspace/speak-dutch-to-me/pi-assistant
nano main.py                    # Edit
./stop_assistant.sh && ./start_assistant.sh  # Restart
tail -f logs/assistant.log      # Monitor

# Git workflow
git pull                        # Get updates
git add -A                      # Stage changes
git commit -m "message"         # Commit
git push                        # Push to GitHub

# Status checks
./status_assistant.sh           # Full status
lsof -i :8080                  # Check port
ps aux | grep python            # Check processes
```

## Resources

- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **Jinja2 Templates:** https://jinja.palletsprojects.com/
- **Tailwind CSS:** https://tailwindcss.com/ (for modern UI)
- **Ollama API:** https://github.com/ollama/ollama/blob/main/docs/api.md
- **Picamera2:** https://datasheets.raspberrypi.com/camera/picamera2-manual.pdf

---

**Ready to start developing? Let's improve that UI!** 🎨
