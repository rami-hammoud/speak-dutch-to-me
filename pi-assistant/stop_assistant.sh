#!/bin/bash

# Pi Assistant Stop Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Load environment variables to get port
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${PORT:-8080}

print_info "Stopping Pi Assistant..."

# Find processes using the port
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
    
    print_info "Found process on port $PORT:"
    echo "  PID: $PID"
    echo "  Command: $PROCESS"
    echo ""
    
    # Graceful shutdown
    print_info "Sending SIGTERM..."
    kill $PID 2>/dev/null
    
    # Wait up to 5 seconds for graceful shutdown
    for i in {1..5}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            print_success "Pi Assistant stopped gracefully"
            exit 0
        fi
        sleep 1
    done
    
    # Force kill if still running
    if ps -p $PID > /dev/null 2>&1; then
        print_warning "Process still running, forcing shutdown..."
        kill -9 $PID 2>/dev/null
        sleep 1
        
        if ! ps -p $PID > /dev/null 2>&1; then
            print_success "Pi Assistant stopped (forced)"
        else
            print_error "Failed to stop process $PID"
            exit 1
        fi
    fi
else
    print_warning "No Pi Assistant process found on port $PORT"
    
    # Check for any Python processes running main.py
    if pgrep -f "python.*main.py" > /dev/null 2>&1; then
        print_info "Found Python processes running main.py:"
        ps aux | grep "python.*main.py" | grep -v grep
        echo ""
        read -p "Kill these processes? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pkill -f "python.*main.py"
            print_success "Processes killed"
        fi
    else
        print_info "Pi Assistant is not running"
    fi
fi

exit 0
