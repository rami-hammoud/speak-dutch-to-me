#!/bin/bash

# Pi Assistant Status Check Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${PORT:-8080}
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
print_header "Pi Assistant Status Check"
echo ""

# Check 1: Virtual Environment
print_info "Checking virtual environment..."
if [ -d "venv" ]; then
    print_success "Virtual environment exists"
else
    print_error "Virtual environment not found"
fi

# Check 2: Configuration
print_info "Checking configuration..."
if [ -f ".env" ]; then
    print_success ".env file exists"
else
    print_error ".env file not found"
fi

# Check 3: Process Status
print_info "Checking if Pi Assistant is running..."
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
    UPTIME=$(ps -p $PID -o etime= 2>/dev/null | xargs)
    
    print_success "Pi Assistant is RUNNING"
    echo "  • PID: $PID"
    echo "  • Process: $PROCESS"
    echo "  • Uptime: $UPTIME"
    echo "  • Port: $PORT"
else
    print_warning "Pi Assistant is NOT running"
fi

# Check 4: Web Interface
print_info "Checking web interface..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>&1 | grep -q "200\|301\|302"; then
    print_success "Web interface is accessible"
    echo "  • URL: http://$IP_ADDR:$PORT"
    echo "  • Dutch Learning: http://$IP_ADDR:$PORT/dutch-learning"
else
    print_warning "Web interface is not accessible"
fi

# Check 5: Ollama
print_info "Checking Ollama service..."
if systemctl is-active --quiet ollama 2>/dev/null; then
    print_success "Ollama service is running"
    if command -v ollama &>/dev/null; then
        MODELS=$(ollama list 2>/dev/null | grep -v "^NAME" | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')
        if [ -n "$MODELS" ]; then
            echo "  • Models: $MODELS"
        fi
    fi
else
    print_warning "Ollama service is not running"
fi

# Check 6: Virtual Camera
print_info "Checking virtual camera..."
if [ -e "/dev/video10" ]; then
    print_success "Virtual camera device exists (/dev/video10)"
else
    print_warning "Virtual camera not loaded (reboot may be needed)"
fi

# Check 7: Logs
print_info "Checking logs..."
if [ -f "logs/assistant.log" ]; then
    LOG_SIZE=$(du -h logs/assistant.log | cut -f1)
    LOG_LINES=$(wc -l < logs/assistant.log)
    print_success "Log file exists"
    echo "  • Size: $LOG_SIZE"
    echo "  • Lines: $LOG_LINES"
    echo ""
    echo "Recent errors (last 5):"
    grep -i "error\|exception\|failed" logs/assistant.log | tail -5 | sed 's/^/    /'
else
    print_warning "Log file not found"
fi

# Check 8: Systemd Service (if installed)
print_info "Checking systemd service..."
if systemctl list-unit-files | grep -q "pi-assistant.service"; then
    if systemctl is-active --quiet pi-assistant; then
        print_success "Systemd service is active"
    elif systemctl is-enabled --quiet pi-assistant; then
        print_warning "Systemd service is enabled but not running"
    else
        print_info "Systemd service is installed but not enabled"
    fi
else
    print_info "Systemd service not installed (using manual start)"
fi

echo ""
print_header "Summary"
echo ""

if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "✅ Pi Assistant is operational"
    echo ""
    echo "Access URLs:"
    echo "  • Main: http://$IP_ADDR:$PORT"
    echo "  • Dutch Learning: http://$IP_ADDR:$PORT/dutch-learning"
    echo ""
    echo "Management:"
    echo "  • Stop: ./stop_assistant.sh"
    echo "  • Logs: tail -f logs/assistant.log"
    echo "  • Restart: ./stop_assistant.sh && ./start_assistant.sh"
else
    echo "⚠️  Pi Assistant is not running"
    echo ""
    echo "To start:"
    echo "  ./start_assistant.sh"
fi

echo ""
