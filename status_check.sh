#!/bin/bash

# Quick Status Check for Dutch Learning Pi Assistant
# Check all system components and their status

echo "🇳🇱 Dutch Learning Pi Assistant - Quick Status"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# System check
echo ""
echo "🔍 System Check"
if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown Pi")
    print_success "Running on: $model"
else
    print_warning "Not on Raspberry Pi (development mode)"
fi

# AI HAT+ check
echo ""
echo "🤖 AI HAT+ Check" 
if lspci 2>/dev/null | grep -i hailo; then
    print_success "Hailo device detected"
else
    print_warning "Hailo device not found"
fi

# Ollama check
echo ""
echo "🧠 Ollama Check"
if command -v ollama >/dev/null 2>&1; then
    if systemctl is-active --quiet ollama; then
        if ollama list | grep -q llama3.2; then
            print_success "Ollama + llama3.2 ready"
        else
            print_warning "Ollama running but llama3.2 missing"
        fi
    else
        print_warning "Ollama installed but not running"
    fi
else
    print_error "Ollama not installed"
fi

# Audio check
echo ""
echo "🔊 Audio Check"
if systemctl --user is-active --quiet pulseaudio 2>/dev/null; then
    print_success "Audio system ready"
else
    print_warning "Audio system needs setup"
fi

# Pi Assistant check
echo ""
echo "🐍 Assistant Check"
if [ -f "pi-assistant/main.py" ]; then
    if [ -f "pi-assistant/.env" ]; then
        if pgrep -f "main.py" >/dev/null 2>&1; then
            print_success "Dutch Assistant running"
        else
            print_info "Assistant ready to start"
        fi
    else
        print_warning "Assistant needs configuration"
    fi
else
    print_error "Assistant code not found"
fi

# Quick actions
echo ""
echo "🚀 Quick Actions"
echo "---------------"

if ! command -v ollama >/dev/null || ! systemctl is-active --quiet ollama; then
    echo "1. Configure Ollama: ./configure_ollama_ai_hat.sh"
fi

if ! systemctl --user is-active --quiet pulseaudio 2>/dev/null; then
    echo "2. Fix audio: ./fix_audio.sh"
fi

if [ ! -f "pi-assistant/.env" ]; then
    echo "3. Setup assistant: ./setup_dutch_assistant.sh"
fi

if [ -f "pi-assistant/.env" ] && ! pgrep -f "main.py" >/dev/null 2>&1; then
    echo "4. Start learning: ./start_dutch_assistant.sh"
fi

echo ""
print_info "Access web interface at: http://localhost:8080/dutch"
echo ""
print_info "For detailed testing:"
echo "   • python3 test_ollama_performance.py"
echo "   • python3 test_audio.py"
