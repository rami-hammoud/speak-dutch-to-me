# 🎯 Master Deployment Script - Complete

## ✅ What I've Done

I've consolidated **ALL deployment scripts** into **ONE master script**: `deploy.sh`

This is now the ONLY script you need for everything!

---

## 📦 The ONE Script: `deploy.sh`

### What It Does

**Handles Everything:**
- ✅ Fresh installation on new Pi
- ✅ Updating existing installation
- ✅ System dependencies (ffmpeg, FLAC)
- ✅ Python virtual environment (PEP 668 compliant)
- ✅ All Python packages
- ✅ Optional HTTPS setup with SSL certificates
- ✅ Systemd service configuration
- ✅ Auto-start on boot
- ✅ Service management

### Usage Options

```bash
# Full deployment with HTTPS (RECOMMENDED)
./deploy.sh --https

# Quick update (after git pull)
./deploy.sh --quick --https

# Full deployment without HTTPS
./deploy.sh

# Quick update without HTTPS
./deploy.sh --quick

# Show help
./deploy.sh --help
```

---

## 🚀 Quick Start Guide

### From Scratch (New Pi)

```bash
# Clone repo
git clone https://github.com/rami-hammoud/speak-dutch-to-me.git
cd speak-dutch-to-me

# Deploy with HTTPS
./deploy.sh --https

# Access at:
# https://YOUR_PI_IP:8080/voice-chat
```

### Update Existing Installation

```bash
cd ~/workspace/speak-dutch-to-me
git pull
./deploy.sh --quick --https
```

### One-Liner Remote Deployment

```bash
curl -sSL https://raw.githubusercontent.com/rami-hammoud/speak-dutch-to-me/main/deploy.sh | bash -s -- --https
```

---

## 📋 What Got Consolidated

### ❌ Deprecated Scripts (Don't use these anymore)

| Old Script | Status | Use Instead |
|-----------|--------|-------------|
| `setup_https.sh` | ❌ Deprecated | `deploy.sh --https` |
| `deploy_voice_chat.sh` | ❌ Deprecated | `deploy.sh` |
| `apply_voice_fix.sh` | ❌ Deprecated | `deploy.sh --quick` |
| `install_system_deps.sh` | ❌ Deprecated | Integrated in `deploy.sh` |
| `update_service.sh` | ❌ Deprecated | Integrated in `deploy.sh` |
| `deploy_voice_system.sh` | ❌ Deprecated | `deploy.sh` |
| `deploy_to_pi.sh` | ❌ Deprecated | `deploy.sh` |

### ✅ Current Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **`deploy.sh`** | **👑 MASTER SCRIPT** | **Always!** |
| `setup_bookworm.sh` | Optional Hailo HAT+ setup | Only if using Hailo AI |
| `start_assistant.sh` | Manual start (development) | Only for testing |

---

## 🎯 The Script Flow

```
deploy.sh
    ↓
Step 1: System Update (optional, skip with --quick)
    ↓
Step 2: Install System Dependencies
    - ffmpeg (audio conversion)
    - FLAC (speech recognition)
    - Python, build tools, audio libraries
    ↓
Step 3: Setup Project Directory
    - Clone repo or pull latest
    ↓
Step 4: Python Virtual Environment
    - Create venv
    - Install all Python packages
    - Google Calendar, Speech Recognition, etc.
    ↓
Step 5: Create Directories
    - logs, data, ssl, credentials
    ↓
Step 6: HTTPS Setup (if --https)
    - Generate SSL certificates
    - Configure for HTTPS
    ↓
Step 7: Systemd Service
    - Create service file
    - Configure auto-start
    - Set correct user and paths
    ↓
Step 8: Start Services
    - Start Ollama (if available)
    - Start Pi Assistant
    - Verify running
    ↓
✅ DONE!
```

---

## 📊 Deployment Options Comparison

### Full Deployment (`./deploy.sh --https`)
- **Time:** 5-10 minutes
- **Updates:** System packages + Python packages
- **Use When:** First time, or major system updates needed
- **HTTPS:** Yes (if flag provided)

### Quick Update (`./deploy.sh --quick --https`)
- **Time:** 1-2 minutes
- **Updates:** Only Python packages
- **Use When:** After code changes, bug fixes
- **HTTPS:** Yes (if flag provided)

---

## 📚 Updated Documentation

All documentation now points to `deploy.sh`:

1. **`DEPLOY.md`** - Complete deployment guide
2. **`README.md`** - Updated with one-command install
3. **`QUICK_FIX_VOICE.md`** - Now uses `deploy.sh --quick`
4. **`FIX_VOICE_RECOGNITION.md`** - References `deploy.sh`

---

## ✅ Benefits

### Before (Multiple Scripts)
- ❌ Confusing which script to use
- ❌ Scripts out of sync
- ❌ Missing steps
- ❌ Hard to maintain

### After (One Script)
- ✅ Always use `deploy.sh`
- ✅ All logic in one place
- ✅ Never miss a step
- ✅ Easy to maintain
- ✅ Works from scratch or for updates
- ✅ Flexible with options

---

## 🧪 Testing Checklist

After running `deploy.sh --https`:

```bash
# 1. Check service status
sudo systemctl status pi-assistant

# 2. View logs
sudo journalctl -u pi-assistant -f

# 3. Access web interface
# Open: https://YOUR_PI_IP:8080/voice-chat

# 4. Test voice command
# Click mic, say: "What time is it?"

# 5. Verify HTTPS
# SSL certificate warning appears (normal)
# Can use microphone after bypass
```

---

## 🎉 Summary

**Old Way:**
1. Run `install_system_deps.sh`
2. Run `setup_https.sh`
3. Run `update_service.sh`
4. Run `deploy_voice_chat.sh`
5. Hope you didn't miss anything

**New Way:**
1. Run `./deploy.sh --https`
2. Done! ✅

---

## 🚀 What's Next?

Your repo now has **ONE unified deployment script** that:
- Works on fresh Pi installations
- Updates existing installations
- Includes all dependencies
- Optionally sets up HTTPS
- Auto-starts on boot
- Is fully self-contained

**Just run `./deploy.sh --https` and you're good to go!** 🎯
