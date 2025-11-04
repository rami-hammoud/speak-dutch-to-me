# 🚀 HTTPS Setup - Quick Command Card

## Copy-Paste These Commands on Your Pi

```bash
# 1. SSH into Pi (from your Mac)
ssh pi@YOUR_PI_IP

# 2. Go to project directory
cd ~/workspace/speak-dutch-to-me

# 3. Pull latest code (if needed)
git pull origin main

# 4. Run HTTPS setup
./setup_https.sh

# 5. Check it's running
sudo systemctl status pi-assistant
```

## 📱 Access from Your Mac

Open in browser: `https://YOUR_PI_IP:8080/voice-chat`

**Click "Advanced" → "Proceed" to bypass self-signed cert warning**

---

## 🎤 Test Voice Command

1. Click microphone button
2. Say: **"What time is it?"**
3. AI should respond!

---

## 🔍 Quick Troubleshooting

```bash
# View real-time logs
sudo journalctl -u pi-assistant -f

# Restart service
sudo systemctl restart pi-assistant

# Check SSL files exist
ls -la ~/workspace/speak-dutch-to-me/pi-assistant/ssl/
```

---

**That's it! 🎉 See ENABLE_HTTPS_NOW.md for full details.**
