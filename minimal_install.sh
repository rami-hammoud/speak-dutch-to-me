#!/usr/bin/env bash
# Minimal Python 3.13 installation - only critical packages
# Use this if fix_python313.sh fails
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Minimal Python 3.13 Installation     ║${NC}"
echo -e "${GREEN}║  (Core packages only)                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cd "$(dirname "$0")/pi-assistant"

# Clean slate
log "Removing old virtual environment..."
rm -rf venv

# Install system packages
log "Installing system packages..."
sudo apt update
sudo apt install -y python3-opencv python3-numpy python3-pyaudio python3-pil

# Create venv with system packages
log "Creating virtual environment..."
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Upgrade pip and setuptools ONLY
log "Upgrading pip and setuptools..."
pip install --upgrade pip
pip install --upgrade "setuptools>=70.0.0"

# Install ONLY the bare minimum (no build isolation)
export PIP_NO_BUILD_ISOLATION=1

log "Installing FastAPI..."
pip install fastapi

log "Installing Uvicorn..."
pip install uvicorn

log "Installing Jinja2..."
pip install jinja2

log "Installing python-dotenv..."
pip install python-dotenv

log "Installing websockets..."
pip install websockets

log "Installing httpx..."
pip install httpx

log "Installing aiohttp..."
pip install aiohttp

log "Installing aiosqlite..."
pip install aiosqlite

log "Installing psutil..."
pip install psutil

unset PIP_NO_BUILD_ISOLATION

# Test critical imports
log "Testing imports..."
python -c "import fastapi; print('✓ FastAPI')" || exit 1
python -c "import uvicorn; print('✓ Uvicorn')" || exit 1
python -c "import cv2; print('✓ OpenCV')" || exit 1
python -c "import numpy; print('✓ NumPy')" || exit 1

deactivate

echo ""
success "✅ Minimal installation complete!"
echo ""
log "Installed packages:"
echo "  • FastAPI (web framework)"
echo "  • Uvicorn (ASGI server)"
echo "  • Jinja2 (templates)"
echo "  • python-dotenv (config)"
echo "  • websockets (real-time)"
echo "  • httpx/aiohttp (HTTP)"
echo "  • aiosqlite (database)"
echo "  • OpenCV + NumPy (from system)"
echo ""
log "To install optional packages later:"
echo "  source venv/bin/activate"
echo '  export PIP_NO_BUILD_ISOLATION=1'
echo "  pip install anthropic openai SpeechRecognition"
echo ""
log "To start the app:"
echo "  cd $(pwd)"
echo "  ./start_assistant.sh"
echo ""
