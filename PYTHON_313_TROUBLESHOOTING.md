# Python 3.13 Troubleshooting Guide for Raspberry Pi

## Problem: `pkgutil.ImpImporter` Error

### Error Message
```
AttributeError: module 'pkgutil' has no attribute 'ImpImporter'. Did you mean: 'zipimporter'?
```

### Root Cause
Python 3.13 removed the deprecated `pkgutil.ImpImporter` class, which breaks older versions of setuptools and pkg_resources used by many packages.

## Solutions

### Solution 1: Use the Fix Script (RECOMMENDED)
```bash
cd ~/workspace/speak-dutch-to-me
./fix_python313.sh
```

This will:
1. Install system packages for numpy, opencv, and audio
2. Recreate venv with `--system-site-packages`
3. Upgrade setuptools to 70.0.0+
4. Install dependencies in the correct order

### Solution 2: Manual Fix
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant

# Remove old venv
rm -rf venv

# Install system packages first
sudo apt update
sudo apt install -y python3-opencv python3-numpy python3-pyaudio python3-pil

# Create venv with system packages
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Upgrade build tools FIRST
pip install --upgrade pip
pip install --upgrade "setuptools>=70.0.0" "wheel>=0.42.0"

# Install core dependencies
pip install fastapi uvicorn[standard] jinja2 python-dotenv websockets httpx aiohttp

# Install remaining
pip install anthropic openai aiosqlite psutil requests SpeechRecognition pyttsx3
```

### Solution 3: Use Python 3.12 Instead
If Python 3.13 causes too many issues:

```bash
# Install Python 3.12
sudo apt install python3.12 python3.12-venv

# Use it for your project
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Best Practices for Python 3.13 on Raspberry Pi

### 1. Use System Packages for Heavy Libraries
Install via apt (not pip) for better compatibility:
```bash
sudo apt install python3-numpy python3-opencv python3-scipy python3-pil python3-pyaudio
```

### 2. Create Venv with System Packages
```bash
python3 -m venv --system-site-packages venv
```

### 3. Upgrade Build Tools First
```bash
pip install --upgrade pip "setuptools>=70.0.0" wheel
```

### 4. Install in Stages
Don't try to install everything at once:
```bash
# Stage 1: Core web
pip install fastapi uvicorn jinja2

# Stage 2: HTTP
pip install httpx aiohttp requests

# Stage 3: AI (optional)
pip install anthropic openai

# Stage 4: Remaining
pip install -r requirements.txt
```

## Verification

Test your setup:
```bash
source venv/bin/activate

# Test imports
python -c "import fastapi; print('✓ FastAPI')"
python -c "import uvicorn; print('✓ Uvicorn')"
python -c "import cv2; print('✓ OpenCV')"
python -c "import numpy; print('✓ NumPy')"

# Check package versions
pip list | grep -E "(setuptools|pip|wheel)"

# Should show:
# pip           24.x.x
# setuptools    70.x.x or higher
# wheel         0.42.x or higher
```

## Common Issues

### Issue: "No module named 'cv2'"
**Solution**: Install via apt
```bash
sudo apt install python3-opencv
# Create venv with --system-site-packages
```

### Issue: "No module named 'numpy'"
**Solution**: Install via apt
```bash
sudo apt install python3-numpy
```

### Issue: PyAudio installation fails
**Solution**: Use system package
```bash
sudo apt install python3-pyaudio portaudio19-dev
```

### Issue: "ModuleNotFoundError" for system packages in venv
**Solution**: Recreate venv with system packages
```bash
python3 -m venv --system-site-packages venv
```

## Alternative: Docker

If native installation is too problematic, use Docker:

```dockerfile
FROM python:3.12-slim-bookworm
# Use Python 3.12 instead of 3.13
```

## Resources

- Python 3.13 Release Notes: https://docs.python.org/3.13/whatsnew/3.13.html
- Setuptools Compatibility: https://setuptools.pypa.io/
- Raspberry Pi Forums: https://forums.raspberrypi.com/

## Quick Reference

**Check Python version:**
```bash
python3 --version
```

**List installed system packages:**
```bash
dpkg -l | grep python3-
```

**List pip packages:**
```bash
pip list
```

**Check if using system packages:**
```bash
python -c "import sys; print(sys.path)"
# Should include /usr/lib/python3/dist-packages
```

## Success Indicators

✅ No `pkgutil.ImpImporter` errors
✅ Can import cv2, numpy from venv
✅ FastAPI starts without errors
✅ setuptools >= 70.0.0
✅ All critical tests pass

---

**Last Updated**: 2025-10-23  
**Python Version**: 3.13  
**OS**: Raspberry Pi OS (Debian Trixie)
