# 🚀 Quick Deployment & Testing Guide

## 📦 Deploy to Your Pi (3 Steps)

### On Your Pi via SSH:

```bash
# 1. Navigate to project
cd ~/workspace/speak-dutch-to-me

# 2. Pull latest code
git pull origin main

# 3. Run deployment script
./deploy_voice_chat.sh
```

That's it! The script will:
- ✅ Pull latest code
- ✅ Install dependencies
- ✅ Restart services
- ✅ Show you access URLs

---

## 🌐 Access the Voice Chat

Once deployed, open in your browser:

```
http://YOUR_PI_IP:8080/voice-chat
```

Replace `YOUR_PI_IP` with your Pi's IP address (shown at end of deployment)

---

## 🎤 Test Voice Commands

### Shopping Commands
- "Find me a wireless keyboard"
- "Compare prices for a mouse"
- "Show my shopping cart"

### Dutch Learning
- "How do you say hello in Dutch"
- "What's the Dutch word for thank you"
- "Teach me good morning"

### Calendar (after Google setup)
- "What's on my calendar today"
- "Do I have any meetings tomorrow"
- "Schedule a meeting for tomorrow at 2 PM"

### Camera
- "Take a picture"
- "Capture a photo"

---

## 🔍 Monitoring & Debugging

### Check Service Status
```bash
sudo systemctl status pi-assistant
```

### View Live Logs
```bash
sudo journalctl -u pi-assistant -f
```

### Restart Service
```bash
sudo systemctl restart pi-assistant
```

### Check Ollama
```bash
sudo systemctl status ollama
```

---

## 📅 Optional: Google Calendar Setup

If you want calendar features to work:

1. Follow: [GOOGLE_CALENDAR_SETUP.md](./GOOGLE_CALENDAR_SETUP.md)
2. Create Google Cloud project
3. Download `credentials.json`
4. Place in `pi-assistant/` directory
5. First run triggers OAuth flow

**Without Google Calendar setup:**
- Voice chat works ✅
- Shopping works ✅
- Dutch learning works ✅
- Camera works ✅
- Calendar shows placeholder message ⚠️

---

## 🐛 Troubleshooting

### Voice Chat Not Loading
```bash
# Check if service is running
sudo systemctl status pi-assistant

# Check port 8080
sudo netstat -tlnp | grep 8080

# View errors
sudo journalctl -u pi-assistant -n 50
```

### Microphone Not Working
1. Check browser permissions
2. Try different browser (Chrome/Firefox)
3. Check if HTTPS is required (some browsers need it)

### Dependencies Missing
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
pip3 install --user -r requirements.txt
```

### Google Calendar Not Working
- Calendar commands will show "Calendar service not available"
- This is expected until you complete Google setup
- Other features work fine without it

---

## 📊 What's Working

After deployment, you'll have:

✅ **Web Voice Chat Interface**
- Click mic to record
- Real-time status updates
- Chat history with intent badges
- Language switcher (EN/NL)

✅ **4 Active Agents**
- Shopping (ecommerce)
- Dutch Learning
- Personal Assistant (needs Google for calendar)
- Camera

✅ **Voice Recognition**
- Google Speech (default, requires internet)
- Fallback to patterns if AI unavailable

✅ **Multi-language**
- English voice commands
- Dutch voice commands

---

## 🎯 Quick Test Checklist

Once deployed, test in order:

1. ✅ Open voice chat page
2. ✅ Grant microphone permission
3. ✅ Click mic (should pulse)
4. ✅ Say: "Find me a keyboard" (tests shopping)
5. ✅ Say: "How do you say hello in Dutch" (tests Dutch learning)
6. ✅ Say: "Take a picture" (tests camera)
7. ⏳ Say: "What's on my calendar" (needs Google setup)

---

## 📚 Documentation

- **Full Guide:** [VOICE_SYSTEM_GUIDE.md](./VOICE_SYSTEM_GUIDE.md)
- **Google Setup:** [GOOGLE_CALENDAR_SETUP.md](./GOOGLE_CALENDAR_SETUP.md)
- **What's New:** [WHATS_NEW.md](./WHATS_NEW.md)
- **Implementation:** [IMPLEMENTATION_COMPLETE.md](./IMPLEMENTATION_COMPLETE.md)

---

## 🎉 Success Indicators

You'll know it's working when you see:

1. ✅ Voice chat page loads with gradient design
2. ✅ Mic button responds to clicks (pulses when recording)
3. ✅ Status text updates as you speak
4. ✅ Your command appears in chat history
5. ✅ Assistant response appears below
6. ✅ Intent badge shows which agent handled it

---

## 💡 Pro Tips

1. **Keyboard Shortcut:** Hold SPACE to record (release to stop)
2. **Language Switch:** Click flag icons to change between EN/NL
3. **Clear History:** Click "Clear History" button to reset chat
4. **View Logs:** Keep logs open while testing: `sudo journalctl -u pi-assistant -f`
5. **Speak Clearly:** Pause briefly after clicking mic before speaking

---

## 🔄 Update Workflow (Future)

When we add more features:

```bash
# On Pi
cd ~/workspace/speak-dutch-to-me
git pull origin main
./deploy_voice_chat.sh
```

Simple!

---

## 📞 Need Help?

If something doesn't work:

1. Check logs: `sudo journalctl -u pi-assistant -n 100`
2. Restart service: `sudo systemctl restart pi-assistant`
3. Check this guide's troubleshooting section
4. Review error messages in browser console (F12)

---

**Ready to test!** 🚀

SSH into your Pi and run:
```bash
cd ~/workspace/speak-dutch-to-me && ./deploy_voice_chat.sh
```
