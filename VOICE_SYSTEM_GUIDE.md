# 🚀 Voice Command System - Quick Start Guide

Complete AI-powered voice assistant with shopping, Dutch learning, calendar management, and camera control via MCP agents.

## 🎯 What's Included

### ✅ Phase 1: Web UI Voice Integration (COMPLETE)
- **Voice Chat Interface** at `/voice-chat`
- Real-time WebSocket voice command processing
- Visual feedback and chat history
- Multi-language support (English/Dutch)
- Audio playback of responses

### ✅ Phase 2: Personal Assistant with Google Calendar (COMPLETE)
- **Calendar Management** via voice commands
- Google Calendar API integration
- Natural language time parsing
- Event creation, listing, searching
- Full MCP agent implementation

## 🏃 Quick Start (3 Steps)

### 1. Install Dependencies

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Install all dependencies including Google Calendar
pip install -r requirements.txt
```

### 2. Set Up Google Calendar (Optional but Recommended)

Follow the detailed guide: [GOOGLE_CALENDAR_SETUP.md](../GOOGLE_CALENDAR_SETUP.md)

**Quick version:**
1. Create a Google Cloud project
2. Enable Calendar API
3. Download `credentials.json`
4. Place it in `pi-assistant/` directory

### 3. Start the Assistant

```bash
python main.py
```

Then open in browser:
- **Voice Chat:** http://localhost:8080/voice-chat
- **Dutch Learning:** http://localhost:8080/dutch-learning
- **Main Dashboard:** http://localhost:8080/

## 🎤 Voice Commands You Can Use

### 🛒 Shopping
```
"Find me a wireless keyboard"
"Compare prices for a mouse"
"Add keyboard to my cart"
"Show my shopping cart"
```

### 🇳🇱 Dutch Learning
```
"How do you say hello in Dutch"
"What's the Dutch word for thank you"
"Teach me good morning in Dutch"
"Show my vocabulary"
```

### 📅 Calendar (Requires Google Setup)
```
"What's on my calendar today"
"Do I have any meetings tomorrow"
"Schedule a meeting for tomorrow at 2 PM"
"Add a dentist appointment for next Monday at 10 AM"
"What's my schedule this week"
```

### 📸 Camera
```
"Take a picture"
"Capture a photo"
```

## 🌐 Web Interface Features

### Voice Chat Page (`/voice-chat`)
- **🎤 Microphone Button**: Click to record, click again to stop
- **🌍 Language Switcher**: Toggle between English 🇺🇸 and Dutch 🇳🇱
- **💬 Chat History**: See all your commands and responses
- **🏷️ Intent Badges**: Visual indicators showing what agent handled each command
- **⌨️ Keyboard Shortcut**: Hold SPACE to record (release to stop)

### Visual Feedback
- **Recording**: Pulsing animation while listening
- **Processing**: Spinning animation while thinking
- **Status Messages**: Real-time status updates
- **Agent Indicators**: Shows active agents (Shopping, Dutch, Calendar, Camera)

## 🧪 Testing the System

Run the complete demo:

```bash
python demo_voice_system.py
```

This will demonstrate:
- ✅ Pattern matching accuracy
- ✅ Shopping agent
- ✅ Dutch learning agent
- ✅ Calendar management
- ✅ Camera control
- ✅ All voice command types

## 📁 Key Files

### Voice System Core
- `services/voice_command_router.py` - Main routing logic, AI intent parsing
- `services/voice_recognition_service.py` - Speech-to-text (Google, Whisper, Vosk)
- `services/tts_service.py` - Text-to-speech (Google TTS, pyttsx3)

### MCP Agents
- `mcp/modules/ecommerce.py` - Shopping agent
- `mcp/modules/dutch_learning.py` - Dutch learning agent
- `mcp/modules/personal_assistant.py` - Calendar & personal assistant
- `mcp/server.py` - MCP tool registration

### Google Calendar
- `services/google_calendar_service.py` - Google Calendar API wrapper
- `credentials.json` - OAuth credentials (create via Google Cloud)
- `token.pickle` - Access token (auto-generated on first auth)

### Web Interface
- `templates/voice_chat.html` - Voice chat UI
- `main.py` - FastAPI app with WebSocket handlers

## 🔧 Configuration

### Voice Recognition Backends

In `services/voice_recognition_service.py`, you can choose:
- **Google** (default, requires internet)
- **Whisper** (OpenAI, high accuracy)
- **Vosk** (offline, good for Pi)

### TTS Backends

In `services/tts_service.py`:
- **Google TTS** (default, natural sounding)
- **pyttsx3** (offline, good for Pi)

### AI Provider

In `main.py`:
- **Ollama** (local, runs on Pi)
- **OpenAI** (cloud, high accuracy)
- **Anthropic** (cloud, Claude)

## 📊 Architecture Overview

```
┌─────────────────┐
│  Voice Input    │ 🎤
│  (Browser/Mic)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  WebSocket Handler (main.py)       │
├─────────────────────────────────────┤
│  1. Receive audio                   │
│  2. Speech-to-text                  │
│  3. Parse command (AI/patterns)     │
│  4. Route to agent                  │
│  5. Execute via MCP                 │
│  6. Text-to-speech                  │
│  7. Send response                   │
└─────────────────────────────────────┘
         │
         ├──────────────┬─────────────┬──────────────┐
         ▼              ▼             ▼              ▼
    ┌──────┐      ┌──────┐     ┌──────────┐   ┌────────┐
    │ Shop │      │Dutch │     │ Calendar │   │ Camera │
    │Agent │      │Agent │     │  Agent   │   │ Agent  │
    └──────┘      └──────┘     └──────────┘   └────────┘
         │              │             │              │
         ▼              ▼             ▼              ▼
    [Products]    [Vocabulary]  [Google Cal]   [Photos]
```

## 🎓 How It Works

### 1. Voice Recognition
```
Browser Mic → WebSocket → speech_recognition.recognize()
→ Text: "What's on my calendar today"
```

### 2. Intent Parsing
```
Text → VoiceCommandRouter.parse_command()
→ Intent: INFORMATION
→ Agent: personal_assistant
→ Action: calendar_list_events
→ Parameters: {"timeframe": "today"}
```

### 3. Agent Execution
```
MCPServer.execute_tool("calendar_list_events", params)
→ PersonalAssistantModule._list_calendar_events()
→ GoogleCalendarService.get_today_events()
→ Results: [events...]
```

### 4. Response Generation
```
Results → VoiceCommandRouter._format_response()
→ Text: "You have 3 events today: Team meeting at 10am, ..."
```

### 5. Speech Synthesis
```
Text → TTSService.speak()
→ Audio file → WebSocket → Browser plays audio
```

## 🎨 Customization

### Add New Command Patterns

Edit `voice_command_router.py`:

```python
self.command_patterns[CommandIntent.YOUR_INTENT] = [
    r"your regex pattern here",
    r"another pattern",
]
```

### Add New MCP Agent

1. Create `mcp/modules/your_agent.py`
2. Implement tool handlers
3. Register in `mcp/server.py`
4. Add patterns to `voice_command_router.py`

### Customize Response Messages

Edit `_format_response()` in `voice_command_router.py`:

```python
if command.intent == CommandIntent.YOUR_INTENT:
    return f"Your custom response: {result.get('data')}"
```

## 🐛 Troubleshooting

### Voice not recognized
- Check microphone permissions in browser
- Ensure internet connection (for Google Speech)
- Try different voice recognition backend

### Calendar not working
- Run through `GOOGLE_CALENDAR_SETUP.md`
- Check `credentials.json` exists
- Delete `token.pickle` and re-authenticate

### Agent not responding
- Check MCP server initialization in logs
- Verify agent is registered in `mcp/server.py`
- Check command patterns match your voice input

### WebSocket connection fails
- Check FastAPI server is running
- Verify port 8080 is not blocked
- Check browser console for errors

## 📚 Documentation

- **[GOOGLE_CALENDAR_SETUP.md](../GOOGLE_CALENDAR_SETUP.md)** - Google Calendar setup
- **[PROJECT_STATE.md](../PROJECT_STATE.md)** - Project overview
- **[README.md](../README.md)** - Main project README

## 🔜 Roadmap

### Next Priority: Additional Integrations
- [ ] Task management (Todoist, Things)
- [ ] Email (Gmail API)
- [ ] Weather and news
- [ ] Smart home (Home Assistant)
- [ ] Multi-turn conversations
- [ ] Confirmation dialogs
- [ ] Wake word detection
- [ ] Context persistence

## 💡 Pro Tips

1. **Test patterns first**: Run `demo_voice_system.py` to verify patterns match
2. **Use keyboard shortcut**: Hold SPACE in voice chat for quick recording
3. **Check logs**: `tail -f logs/assistant.log` for debugging
4. **Start simple**: Test with shopping before calendar (no auth needed)
5. **Natural language**: Commands work with various phrasings

## 🎉 You're Ready!

Everything is set up and ready to use. Just:

1. `python main.py`
2. Open `http://localhost:8080/voice-chat`
3. Click the mic and speak!

**Enjoy your AI-powered voice assistant!** 🚀

---

*Built with FastAPI, Ollama, Google APIs, and MCP agent architecture*
