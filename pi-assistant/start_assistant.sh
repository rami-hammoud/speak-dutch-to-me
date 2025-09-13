#!/bin/bash

# Pi Assistant Startup Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found. Please run setup_pi_assistant.sh first."
    exit 1
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please run setup_pi_assistant.sh first."
    exit 1
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

print_info "Starting Pi Assistant..."
print_info "Web interface will be available at: http://$(hostname -I | awk '{print $1}'):${PORT:-8080}"
print_info "Press Ctrl+C to stop the assistant"

# Start the application
python main.py
