# 📅 Google Calendar Integration Setup Guide

This guide will help you set up Google Calendar integration for the Pi Assistant voice command system.

## 🎯 What You'll Be Able To Do

Once set up, you can use voice commands like:
- "What's on my calendar today?"
- "Do I have any meetings tomorrow?"
- "Add a meeting for tomorrow at 2 PM"
- "Schedule a dentist appointment for next Monday at 10 AM"
- "What meetings do I have this week?"

## 📋 Prerequisites

1. A Google Account
2. Access to Google Cloud Console
3. Python 3.8 or higher installed

## 🚀 Step-by-Step Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it "Pi Assistant" (or any name you like)
4. Click "Create"

### Step 2: Enable Google Calendar API

1. In your new project, go to "APIs & Services" → "Library"
2. Search for "Google Calendar API"
3. Click on it and then click "Enable"

### Step 3: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure the OAuth consent screen:
   - User Type: External
   - App name: "Pi Assistant"
   - User support email: Your email
   - Developer contact: Your email
   - Scopes: Add `https://www.googleapis.com/auth/calendar`
   - Test users: Add your email
   - Click "Save and Continue"

4. Back to "Create OAuth client ID":
   - Application type: "Desktop app"
   - Name: "Pi Assistant Desktop"
   - Click "Create"

5. **Download the credentials JSON file**
   - Click the download button (⬇️) next to your newly created OAuth client
   - Save it as `credentials.json`

### Step 4: Install Dependencies

On your Raspberry Pi or development machine:

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Install Google Calendar dependencies
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

### Step 5: Place Credentials File

1. Copy your `credentials.json` file to the pi-assistant directory:

```bash
# If you downloaded it on your computer, scp it to the Pi:
scp ~/Downloads/credentials.json pi@YOUR_PI_IP:~/workspace/speak-dutch-to-me/pi-assistant/

# Or if you're on the Pi, move it from Downloads:
mv ~/Downloads/credentials.json ~/workspace/speak-dutch-to-me/pi-assistant/
```

2. Verify the file is in the right place:

```bash
ls -la ~/workspace/speak-dutch-to-me/pi-assistant/credentials.json
```

### Step 6: First-Time Authentication

The first time you run the assistant with calendar features, you'll need to authenticate:

```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Run the assistant
python main.py
```

Then access the voice chat interface:
- Open browser: `http://PI_IP:8080/voice-chat`
- Say: "What's on my calendar today?"

**On first use:**
1. A browser window will open asking you to sign in to Google
2. Select your Google account
3. Grant permission to access your calendar
4. You'll see "The authentication flow has completed"
5. A `token.pickle` file will be created (this stores your credentials securely)

**Note:** If you're running headless (no display), you'll see a URL in the terminal. Copy it to a browser on another device, complete authentication, then paste the auth code back.

## 🔐 Security Notes

- **credentials.json** contains your OAuth client secret - keep it private
- **token.pickle** contains your access token - keep it private
- Add both to `.gitignore` to avoid committing them:

```bash
echo "credentials.json" >> .gitignore
echo "token.pickle" >> .gitignore
```

## 🧪 Testing

Test your calendar integration:

```python
# Create a test script: test_calendar.py
import asyncio
from services.google_calendar_service import get_calendar_service

async def test():
    service = await get_calendar_service()
    events = await service.get_today_events()
    
    print(f"Found {len(events)} events today:")
    for event in events:
        print(f"  - {event['summary']} at {event['start']}")

asyncio.run(test())
```

Run it:
```bash
python test_calendar.py
```

## 🎤 Voice Commands Reference

### List Events
- "What's on my calendar today?"
- "Show me my calendar"
- "Do I have any meetings tomorrow?"
- "What's my schedule this week?"

### Create Events
- "Schedule a meeting for tomorrow at 2 PM"
- "Add a dentist appointment for next Monday at 10 AM"
- "Create an event called team lunch tomorrow at noon"

### Search Events
- "When is my dentist appointment?"
- "Find my team meeting"

## 🔧 Troubleshooting

### Error: "credentials.json not found"
- Make sure you've downloaded and placed the file in the correct directory
- Check the path: `~/workspace/speak-dutch-to-me/pi-assistant/credentials.json`

### Error: "Calendar service not available"
- Install dependencies: `pip install google-auth google-auth-oauthlib google-api-python-client`
- Restart the assistant

### Error: "Token expired" or "Invalid token"
- Delete `token.pickle` and re-authenticate
- Run: `rm token.pickle` then restart the assistant

### Authentication doesn't open browser
- Look for a URL in the terminal output
- Copy it to a browser manually
- Complete authentication and copy the code back

## 📚 Advanced Configuration

### Using Multiple Calendars

By default, the system uses your primary calendar. To use a specific calendar:

1. Get the calendar ID from Google Calendar settings
2. Pass it in voice commands (requires code modification)

### Customizing Time Zone

Edit `google_calendar_service.py` and change:
```python
'timeZone': 'UTC',
```
to your timezone:
```python
'timeZone': 'America/New_York',  # or your timezone
```

### Setting Default Event Duration

Events default to 60 minutes. Change in `personal_assistant.py`:
```python
duration_minutes = params.get("duration_minutes", 60)  # Change 60 to desired default
```

## 🎉 You're All Set!

Your Pi Assistant can now manage your Google Calendar via voice commands!

Try saying:
- "What do I have today?"
- "Schedule a team meeting tomorrow at 3 PM"
- "What's on my calendar this week?"

## 🔜 Coming Soon

- [ ] Task management (Todoist/Things integration)
- [ ] Email integration (Gmail)
- [ ] Reminders and notifications
- [ ] Calendar invites and RSVP
- [ ] Multiple calendar support
- [ ] Recurring events

---

**Questions?** Check the [main README](../README.md) or open an issue on GitHub.
