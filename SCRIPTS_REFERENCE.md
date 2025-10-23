# Setup Scripts - Quick Reference

## 🎯 Main Setup Script

**`setup_trixie.sh`** - The ONE script you need to deploy on a fresh Raspberry Pi

```bash
# Clone and run
git clone <your-repo>
cd speak-dutch-to-me
chmod +x setup_trixie.sh
./setup_trixie.sh
```

This script:
- ✅ Installs all system dependencies
- ✅ Sets up Python 3.13 environment correctly
- ✅ Installs Ollama + llama3.2:3b
- ✅ Configures camera and audio
- ✅ Creates virtual camera for Zoom/Meet
- ✅ Sets up systemd services (optional)
- ✅ Creates `.env` from `.env.example`

## 📋 Helper Scripts

### `verify_installation.sh`
Tests all components after installation to ensure everything works.

```bash
./verify_installation.sh
```

Checks:
- Python environment
- System packages (OpenCV, NumPy)
- Camera utilities
- Virtual camera
- Ollama service
- Audio system
- Database
- Configuration files

### `manage_virtual_camera.sh`
Controls the virtual camera stream for Zoom/Google Meet.

```bash
./manage_virtual_camera.sh start   # Start streaming
./manage_virtual_camera.sh stop    # Stop streaming
./manage_virtual_camera.sh status  # Check status
```

## 🗑️ Removed Scripts (Deprecated)

The following scripts have been removed as they're no longer needed:

- ❌ `setup_raspberry_pi.sh` - Replaced by `setup_trixie.sh`
- ❌ `setup_raspberry_pi_trixie.sh` - Renamed to `setup_trixie.sh`
- ❌ `setup_pi_complete.sh` - Merged into `setup_trixie.sh`
- ❌ `setup_virtual_camera.sh` - Integrated into `setup_trixie.sh`
- ❌ `fix_python313.sh` - No longer needed (handled in main script)
- ❌ `minimal_install.sh` - No longer needed (handled in main script)

## 📁 Configuration Files

### `pi-assistant/.env.example`
Template configuration file. The setup script copies this to `.env`.

**After installation, edit `.env` to add your API keys:**

```bash
cd pi-assistant
nano .env
```

Required settings (already configured by default):
- `HOST`, `PORT` - Web server settings
- `OLLAMA_HOST`, `OLLAMA_MODEL` - Local LLM settings

Optional settings (add if you want):
- `OPENAI_API_KEY` - For GPT-4 access
- `ANTHROPIC_API_KEY` - For Claude access
- `BRAVE_SEARCH_API_KEY` - For web search

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Comprehensive setup documentation
  - Manual installation steps
  - Troubleshooting guide
  - System requirements
  - Useful commands

- **[PYTHON_313_TROUBLESHOOTING.md](PYTHON_313_TROUBLESHOOTING.md)** - Python 3.13 specific issues
  - pkgutil.ImpImporter errors
  - setuptools compatibility
  - System vs pip packages

- **[README.md](README.md)** - Project overview and quick start

## 🚀 Quick Start Reminder

### For a Brand New Raspberry Pi:

1. **Flash Debian Trixie** to SD card

2. **Clone and run setup:**
   ```bash
   git clone <your-repo>
   cd speak-dutch-to-me
   ./setup_trixie.sh
   ```

3. **Configure and start:**
   ```bash
   cd pi-assistant
   nano .env  # Optional: add API keys
   ./start_assistant.sh
   ```

4. **Access:**
   - Web UI: http://YOUR_PI_IP:8080
   - Dutch learning: http://YOUR_PI_IP:8080/dutch-learning

5. **Reboot (recommended):**
   ```bash
   sudo reboot
   ```

### For CI/CD / Automated Deployment:

```bash
# Non-interactive mode
export NON_INTERACTIVE=true
./setup_trixie.sh

# Or with flags
./setup_trixie.sh --help
```

## ✅ What Changed

### Before (Multiple Scripts)
- Multiple setup scripts with overlapping functionality
- Unclear which script to run
- Manual .env creation required
- Inconsistent Python 3.13 handling

### After (Single Script)
- ✅ One script: `setup_trixie.sh`
- ✅ Automatic .env creation from template
- ✅ Python 3.13 fully supported
- ✅ CI/CD friendly with non-interactive mode
- ✅ Comprehensive error handling and verification

## 🆘 If You Have Issues

1. **Run verification:**
   ```bash
   ./verify_installation.sh
   ```

2. **Check logs:**
   ```bash
   tail -f pi-assistant/logs/assistant.log
   ```

3. **See troubleshooting:**
   - [SETUP_GUIDE.md](SETUP_GUIDE.md#troubleshooting)
   - [PYTHON_313_TROUBLESHOOTING.md](PYTHON_313_TROUBLESHOOTING.md)

4. **Start fresh:**
   ```bash
   cd pi-assistant
   rm -rf venv
   cd ..
   ./setup_trixie.sh
   ```
