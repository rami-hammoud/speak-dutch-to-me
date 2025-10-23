#!/bin/bash

# Pi Assistant Startup Script

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

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found. Please run setup_trixie.sh first."
    exit 1
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Creating from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success ".env created from template"
    else
        print_error ".env.example not found. Cannot continue."
        exit 1
    fi
fi

# Load environment variables
set -a
source .env
set +a

# Get port from environment or default
PORT=${PORT:-8080}
HOST=${HOST:-0.0.0.0}

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    print_warning "Port $PORT is already in use!"
    
    # Find the process using the port
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
    
    echo ""
    echo "Process using port $PORT:"
    echo "  PID: $PID"
    echo "  Command: $PROCESS"
    echo ""
    
    # Check if it's our own process
    if ps -p $PID -o cmd= 2>/dev/null | grep -q "main.py\|uvicorn"; then
        print_info "Found existing Pi Assistant instance"
        read -p "Kill existing process and restart? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Stopping existing instance..."
            kill $PID 2>/dev/null
            sleep 2
            
            # Force kill if still running
            if ps -p $PID > /dev/null 2>&1; then
                print_warning "Process still running, force killing..."
                kill -9 $PID 2>/dev/null
                sleep 1
            fi
            
            print_success "Previous instance stopped"
        else
            print_error "Cannot start - port is in use"
            echo ""
            echo "To manually stop the process, run:"
            echo "  kill $PID"
            echo ""
            exit 1
        fi
    else
        print_error "Port $PORT is in use by another application: $PROCESS"
        echo ""
        echo "Options:"
        echo "  1. Stop the other application"
        echo "  2. Change PORT in .env file"
        echo "  3. Kill the process: kill $PID"
        echo ""
        exit 1
    fi
fi

# Get IP address for display
IP_ADDR=$(hostname -I | awk '{print $1}')

print_info "Starting Pi Assistant..."
print_success "Web interface will be available at:"
echo "  • http://$IP_ADDR:$PORT"
echo "  • http://$IP_ADDR:$PORT/dutch-learning"
echo "  • http://localhost:$PORT"
echo ""
print_info "Press Ctrl+C to stop the assistant"
echo ""

# Start the application with proper error handling
python main.py 2>&1 | tee -a logs/assistant.log
