# 🎤 Voice Recognition - Quick Fix Commands

## Run These on Your Pi (in order):

```bash
# 1. Go to project directory
cd ~/workspace/speak-dutch-to-me

# 2. Pull latest fixes
git pull origin main

# 3. Install ffmpeg (audio conversion)
./install_system_deps.sh

# 4. Restart service
sudo systemctl restart pi-assistant

# 5. Check it's running
sudo systemctl status pi-assistant
```

## Test It Now!

1. Open: `https://YOUR_PI_IP:8080/voice-chat`
2. Click "Advanced" → "Proceed to 10.0.0.51 (unsafe)" ← This is normal!
3. Click microphone 🎤
4. Say: **"What time is it?"**
5. ✅ Should work!

---

## What Was Fixed?

- ✅ Method name: `recognize_from_bytes()` → `recognize()`
- ✅ Audio format: Added webm → WAV conversion
- ✅ Added ffmpeg for audio processing
- ✅ Fixed base64 decoding

---

## Quick Troubleshooting

```bash
# View real-time logs
sudo journalctl -u pi-assistant -f

# Restart if needed
sudo systemctl restart pi-assistant

# Check ffmpeg installed
ffmpeg -version
```

---

**See `FIX_VOICE_RECOGNITION.md` for full details!**
