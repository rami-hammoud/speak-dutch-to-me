#!/usr/bin/env bash
# Installation Verification Script for Dutch Learning AI Assistant
# Tests all components after setup
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() { echo -e "${BLUE}[TEST]${NC} $*"; }
success() { echo -e "${GREEN}[PASS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ASSISTANT_DIR="$SCRIPT_DIR/pi-assistant"
VENV_DIR="$PI_ASSISTANT_DIR/venv"
DATA_DIR="$PI_ASSISTANT_DIR/data"

failed=0
warnings=0

echo "================================================"
echo "  Dutch Learning AI Assistant - Verification"
echo "================================================"
echo ""

# Test 1: Python Environment
log "Testing Python environment..."
if [[ -f "$VENV_DIR/bin/activate" ]]; then
    source "$VENV_DIR/bin/activate"
    if python -c "import fastapi, uvicorn" 2>/dev/null; then
        success "Python virtual environment and core packages"
    else
        fail "Python environment missing critical packages"
        ((failed++))
    fi
    deactivate
else
    fail "Virtual environment not found at $VENV_DIR"
    ((failed++))
fi

# Test 2: System Packages
log "Testing system packages..."
if python3 -c "import cv2, numpy" 2>/dev/null; then
    success "OpenCV and NumPy (system packages)"
else
    warn "OpenCV/NumPy not available (optional for CV features)"
    ((warnings++))
fi

# Test 3: Camera
log "Testing camera utilities..."
if command -v rpicam-hello &>/dev/null; then
    success "Raspberry Pi camera tools"
else
    warn "Camera utilities not found"
    ((warnings++))
fi

# Test 4: Virtual Camera
log "Testing virtual camera..."
if [[ -e /dev/video10 ]]; then
    success "Virtual camera device /dev/video10"
else
    warn "Virtual camera not loaded (requires reboot or manual modprobe)"
    ((warnings++))
fi

# Test 5: v4l2loopback module
log "Testing v4l2loopback kernel module..."
if lsmod | grep -q v4l2loopback; then
    success "v4l2loopback kernel module loaded"
else
    warn "v4l2loopback not loaded (run: sudo modprobe v4l2loopback)"
    ((warnings++))
fi

# Test 6: Ollama
log "Testing Ollama..."
if command -v ollama &>/dev/null; then
    if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        success "Ollama service running"
        # Check if model is available
        if ollama list | grep -q llama3.2:3b; then
            success "llama3.2:3b model available"
        else
            warn "llama3.2:3b model not found"
            ((warnings++))
        fi
    else
        warn "Ollama installed but not responding (run: sudo systemctl start ollama)"
        ((warnings++))
    fi
else
    warn "Ollama not installed (optional for local LLM)"
    ((warnings++))
fi

# Test 7: Audio
log "Testing audio system..."
if command -v aplay &>/dev/null && command -v arecord &>/dev/null; then
    success "ALSA audio utilities"
else
    warn "Audio utilities incomplete"
    ((warnings++))
fi

if systemctl --user is-active pulseaudio >/dev/null 2>&1; then
    success "PulseAudio service"
else
    warn "PulseAudio not running"
    ((warnings++))
fi

# Test 8: Database
log "Testing database..."
if command -v sqlite3 &>/dev/null; then
    success "SQLite3 available"
else
    fail "SQLite3 not found"
    ((failed++))
fi

if [[ -f "$DATA_DIR/vocabulary.db" ]]; then
    success "Vocabulary database initialized"
else
    warn "Database not yet initialized (will be created on first run)"
    ((warnings++))
fi

# Test 9: Configuration
log "Testing configuration..."
if [[ -f "$PI_ASSISTANT_DIR/.env" ]]; then
    success "Configuration file exists"
    # Check for placeholder values
    if grep -q "your_" "$PI_ASSISTANT_DIR/.env"; then
        warn "Configuration contains placeholder values - update with real API keys"
        ((warnings++))
    fi
else
    warn "Configuration file not found (will use defaults)"
    ((warnings++))
fi

# Test 10: Systemd Services
log "Testing systemd services..."
if systemctl list-unit-files | grep -q pi-assistant.service; then
    success "pi-assistant systemd service registered"
else
    warn "Systemd service not registered"
    ((warnings++))
fi

# Test 11: Network
log "Testing network connectivity..."
if ping -c 1 google.com >/dev/null 2>&1; then
    success "Internet connectivity"
else
    warn "No internet connection (needed for API calls)"
    ((warnings++))
fi

# Test 12: Required directories
log "Testing directory structure..."
for dir in "$PI_ASSISTANT_DIR" "$DATA_DIR" "$PI_ASSISTANT_DIR/logs" "$PI_ASSISTANT_DIR/static" "$PI_ASSISTANT_DIR/templates"; do
    if [[ -d "$dir" ]]; then
        success "Directory: $dir"
    else
        warn "Missing directory: $dir"
        ((warnings++))
    fi
done

# Summary
echo ""
echo "================================================"
echo "  Verification Summary"
echo "================================================"
echo ""

if [[ $failed -eq 0 ]]; then
    success "All critical tests passed!"
    if [[ $warnings -gt 0 ]]; then
        warn "$warnings optional component(s) have warnings"
        echo ""
        echo "The system will work but some features may be limited."
    else
        echo ""
        echo "System is fully operational and ready to use!"
    fi
    exit 0
else
    fail "$failed critical test(s) failed"
    echo ""
    echo "Please fix the failed components before running the assistant."
    exit 1
fi
