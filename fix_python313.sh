#!/usr/bin/env bash
# Fix Python 3.13 dependency issues on Raspberry Pi
# Run this if you get pkgutil.ImpImporter or setuptools errors

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Python 3.13 Dependency Fix for Raspberry Pi ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ASSISTANT_DIR="$SCRIPT_DIR/pi-assistant"
VENV_DIR="$PI_ASSISTANT_DIR/venv"

cd "$PI_ASSISTANT_DIR"

log "Step 1/5: Installing system packages (recommended for Python 3.13)..."
sudo apt update
sudo apt install -y python3-opencv python3-numpy python3-pyaudio python3-pil python3-scipy
success "System packages installed"

log "Step 2/5: Removing old virtual environment..."
if [[ -d "$VENV_DIR" ]]; then
    rm -rf "$VENV_DIR"
    success "Old venv removed"
else
    log "No existing venv found"
fi

log "Step 3/5: Creating new venv with system packages..."
python3 -m venv --system-site-packages "$VENV_DIR"
success "Virtual environment created"

log "Step 4/5: Upgrading build tools..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install --upgrade "setuptools>=70.0.0" "wheel>=0.42.0"
success "Build tools upgraded"

log "Step 5/5: Installing application dependencies..."
log "Installing web framework..."
pip install fastapi uvicorn[standard] jinja2 python-dotenv websockets

log "Installing HTTP clients..."
pip install httpx aiohttp requests

log "Installing AI libraries (optional)..."
pip install anthropic openai || warn "AI libraries failed (optional)"

log "Installing utilities..."
pip install aiosqlite psutil python-multipart

log "Installing audio processing (may use system packages)..."
pip install SpeechRecognition pyttsx3 || warn "Using system audio packages"

log "Installing from requirements-pi.txt (if exists)..."
if [[ -f requirements-pi.txt ]]; then
    pip install -r requirements-pi.txt || warn "Some packages failed"
elif [[ -f requirements.txt ]]; then
    pip install -r requirements.txt || warn "Some packages failed"
fi

log "Verifying critical packages..."
python -c "import fastapi, uvicorn; print('✓ Web framework OK')" || error "FastAPI failed"
python -c "import cv2, numpy; print('✓ Computer vision OK')" || warn "OpenCV not available"
python -c "import sqlite3; print('✓ Database OK')" || error "SQLite failed"

deactivate

echo ""
success "✅ Python 3.13 environment fixed!"
echo ""
log "Next steps:"
echo "  1. Start the assistant: ./start_assistant.sh"
echo "  2. Or manually:"
echo "     source venv/bin/activate"
echo "     python main.py"
echo ""
log "If you still have issues:"
echo "  • Check Python version: python3 --version"
echo "  • View installed packages: pip list"
echo "  • Check system packages: dpkg -l | grep python3-"
echo ""
