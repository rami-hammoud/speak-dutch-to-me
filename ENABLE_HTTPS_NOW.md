# 🔒 Enable HTTPS - Quick Guide

## The Problem
Browser microphone access requires HTTPS (secure connection). Currently your Pi is running on HTTP, so the microphone won't work from your Mac's browser.

## The Solution
Run the HTTPS setup script to generate a self-signed SSL certificate and reconfigure the service.

---

## 📋 Steps to Enable HTTPS

### 1. SSH into Your Pi
```bash
ssh pi@YOUR_PI_IP
# or
ssh pi@raspberrypi.local
```

### 2. Navigate to Project Directory
```bash
cd ~/workspace/speak-dutch-to-me
```

### 3. Make Script Executable (if not already)
```bash
chmod +x setup_https.sh
```

### 4. Run the HTTPS Setup Script
```bash
./setup_https.sh
```

The script will:
- ✅ Generate SSL certificate (valid for 1 year)
- ✅ Install required Python packages
- ✅ Update systemd service for HTTPS
- ✅ Restart the service automatically

### 5. Access from Your Mac's Browser
Open one of these URLs:
```
https://YOUR_PI_IP:8080/voice-chat
https://raspberrypi.local:8080/voice-chat
```

**You will see a security warning** - this is normal for self-signed certificates!

#### How to Bypass the Warning:

**Safari:**
1. Click "Show Details"
2. Click "visit this website"
3. Click "Visit Website" again to confirm

**Chrome:**
1. Click "Advanced"
2. Click "Proceed to [hostname] (unsafe)"

**Firefox:**
1. Click "Advanced"
2. Click "Accept the Risk and Continue"

### 6. Grant Microphone Permission
After bypassing the security warning, your browser will prompt for microphone access. Click "Allow"!

---

## 🔍 Verify It's Working

### Check Service Status
```bash
sudo systemctl status pi-assistant
```

Should show:
- ✅ Active (running)
- ✅ Loaded with HTTPS options

### View Real-time Logs
```bash
sudo journalctl -u pi-assistant -f
```

### Test Microphone
1. Click the microphone button in the web UI
2. Speak: "What time is it?"
3. You should see:
   - Voice input being transcribed
   - AI response
   - Audio playback

---

## 🚨 Troubleshooting

### Service Won't Start
```bash
# Check logs for errors
sudo journalctl -u pi-assistant -n 50

# Ensure SSL files exist
ls -la ~/workspace/speak-dutch-to-me/pi-assistant/ssl/

# Should show:
# cert.pem
# key.pem
```

### Can't Connect from Browser
```bash
# Verify the service is listening on HTTPS
sudo netstat -tlnp | grep 8080

# Check firewall (if enabled)
sudo ufw status
```

### Certificate Error Persists
Clear your browser cache or try a different browser. Self-signed certificates will always show a warning, but you can proceed.

### Microphone Still Not Working
1. Check browser console (F12) for errors
2. Ensure you clicked "Allow" for microphone permission
3. Try a different browser
4. Verify the URL starts with `https://` (not `http://`)

---

## 📝 What Changed?

### Before (HTTP)
```
http://YOUR_PI_IP:8080/voice-chat
❌ No microphone access (browser security restriction)
```

### After (HTTPS)
```
https://YOUR_PI_IP:8080/voice-chat
✅ Microphone access allowed
✅ Secure WebSocket connection
✅ Production-ready
```

---

## 🎯 Next Steps

Once HTTPS is working and you can use the microphone:

1. **Test Voice Commands:**
   - "Add eggs to my shopping list"
   - "What's Dutch for hello?"
   - "Add event: Team meeting tomorrow at 3pm"

2. **Verify Auto-Start:**
   ```bash
   sudo reboot
   # After reboot, check if service auto-started:
   sudo systemctl status pi-assistant
   ```

3. **Optional: Production SSL Certificate**
   For a permanent setup, consider:
   - Using Let's Encrypt (requires domain name)
   - Adding certificate to trusted store
   - See: PRODUCTION_SSL_SETUP.md (coming soon)

---

## ✅ Success Checklist

- [ ] Ran `./setup_https.sh` on Pi
- [ ] Service restarted successfully
- [ ] Accessed `https://YOUR_PI_IP:8080/voice-chat`
- [ ] Bypassed security warning
- [ ] Granted microphone permission
- [ ] Tested voice input successfully
- [ ] Voice commands working with AI responses

---

## 🆘 Need Help?

Check these files for more details:
- `README_DEPLOY.md` - Full deployment guide
- `TROUBLESHOOTING.md` - Common issues and solutions
- `VOICE_SYSTEM_GUIDE.md` - Voice command details

Or check logs:
```bash
# Real-time service logs
sudo journalctl -u pi-assistant -f

# Application logs
tail -f ~/workspace/speak-dutch-to-me/pi-assistant/logs/assistant.log
```

---

**Ready? SSH into your Pi and run `./setup_https.sh` now! 🚀**
