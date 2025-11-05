# 🚀 One-Command Deployment

## TL;DR - Quick Start

On your Raspberry Pi, run:

```bash
curl -sSL https://raw.githubusercontent.com/rami-hammoud/speak-dutch-to-me/main/deploy.sh | bash
```

Or if you already have the repo:

```bash
cd ~/workspace/speak-dutch-to-me
./deploy.sh --https
```

That's it! 🎉

---

## The ONE Script: `deploy.sh`

**`deploy.sh`** is the ONLY script you need. It handles:

- ✅ Fresh installation on a new Pi
- ✅ Updating existing installation  
- ✅ Installing all dependencies (ffmpeg, FLAC, Python packages)
- ✅ Setting up virtual environment (PEP 668 compliant)
- ✅ Configuring systemd service
- ✅ Optional HTTPS setup
- ✅ Starting everything automatically

---

## Usage

### Option 1: Full Deployment (First Time)

```bash
cd ~/workspace/speak-dutch-to-me
./deploy.sh --https
```

**What it does:**
1. Updates system packages
2. Installs ffmpeg, FLAC, and all dependencies
3. Creates Python virtual environment
4. Installs Python packages
5. Generates SSL certificates (HTTPS)
6. Configures systemd service
7. Starts Pi Assistant

**Time:** 5-10 minutes

---

### Option 2: Quick Update (After Code Changes)

```bash
cd ~/workspace/speak-dutch-to-me
git pull
./deploy.sh --quick --https
```

**What it does:**
- ✅ Skips system updates (faster)
- ✅ Pulls latest code
- ✅ Updates Python packages
- ✅ Restarts service

**Time:** 1-2 minutes

---

### Option 3: Remote Deployment (From Your Mac)

```bash
# One command to deploy from scratch
curl -sSL https://raw.githubusercontent.com/rami-hammoud/speak-dutch-to-me/main/deploy.sh | bash -s -- --https
```

---

## Command Options

```bash
./deploy.sh                    # Full deployment without HTTPS
./deploy.sh --https            # Full deployment with HTTPS (recommended)
./deploy.sh --quick            # Quick update (skip system packages)
./deploy.sh --quick --https    # Quick update with HTTPS
./deploy.sh --help             # Show help
```

---

## After Deployment

### Access Your Assistant

**With HTTPS (recommended for microphone):**
```
https://YOUR_PI_IP:8080/voice-chat
```

**Without HTTPS:**
```
http://YOUR_PI_IP:8080/voice-chat
```

### Test Voice Commands

1. Click microphone button 🎤
2. Say: "What time is it?"
3. AI should respond!

Try these:
- "What's Dutch for hello?"
- "Add milk to my shopping list"
- "Add meeting tomorrow at 3pm"

---

## Troubleshooting

### Service Won't Start
```bash
sudo journalctl -u pi-assistant -n 50
```

### Update and Fix Issues
```bash
cd ~/workspace/speak-dutch-to-me
git pull
./deploy.sh --quick --https
```

### Start Over (Fresh Install)
```bash
# Remove old installation
sudo systemctl stop pi-assistant
sudo systemctl disable pi-assistant
rm -rf ~/workspace/speak-dutch-to-me

# Deploy from scratch
mkdir -p ~/workspace
cd ~/workspace
git clone https://github.com/rami-hammoud/speak-dutch-to-me.git
cd speak-dutch-to-me
./deploy.sh --https
```

---

## What About Other Scripts?

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **`deploy.sh`** | **👑 MASTER SCRIPT** | **Always use this!** |
| `setup_https.sh` | ❌ Deprecated | Use `deploy.sh --https` |
| `deploy_voice_chat.sh` | ❌ Deprecated | Use `deploy.sh` |
| `apply_voice_fix.sh` | ❌ Deprecated | Use `deploy.sh --quick` |
| `install_system_deps.sh` | ❌ Deprecated | Integrated in `deploy.sh` |
| `update_service.sh` | ❌ Deprecated | Integrated in `deploy.sh` |
| `setup_bookworm.sh` | Optional | Only for Hailo AI HAT+ setup |

**Bottom line:** Just use `deploy.sh` for everything! 🎯

---

## Quick Reference Card

```bash
# Fresh installation with HTTPS
./deploy.sh --https

# Quick update after git pull
./deploy.sh --quick --https

# Check status
sudo systemctl status pi-assistant

# View logs
sudo journalctl -u pi-assistant -f

# Restart
sudo systemctl restart pi-assistant

# Test
# Open: https://YOUR_PI_IP:8080/voice-chat
```

---

## Documentation

- **Quick Start:** This file!
- **Troubleshooting:** `FIX_VOICE_RECOGNITION.md`
- **Google Calendar:** `GOOGLE_CALENDAR_SETUP.md`
- **Full Guide:** `README_DEPLOY.md`

---

## ✅ Deployment Checklist

After running `./deploy.sh --https`:

- [ ] Service is running: `sudo systemctl status pi-assistant`
- [ ] Can access: `https://YOUR_PI_IP:8080/voice-chat`
- [ ] Bypassed SSL certificate warning
- [ ] Granted microphone permission
- [ ] Voice commands working

---

**That's it! One script, infinite possibilities! 🚀**
