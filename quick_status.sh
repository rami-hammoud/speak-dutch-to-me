#!/bin/bash

# Quick Status Check for Dutch Learning Pi Assistant
# Check all system components and their status

set -e

echo "🇳🇱 Dutch Learning Pi Assistant - System Status"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "🔍 Hardware Detection:"
if lspci 2>/dev/null | grep -i hailo; then
    echo "   ✅ Hailo device found in PCI"
else
    echo "   ❌ No Hailo device in PCI"
fi

echo ""
echo "📋 Recent Kernel Messages:"
dmesg | grep -i hailo | tail -3 || echo "   No recent Hailo messages"

echo ""
echo "🐍 Python Modules:"
python3 -c "
modules = ['hailo_platform_api', 'hailort', 'hailo', 'cv2', 'numpy']
for module in modules:
    try:
        __import__(module)
        print(f'   ✅ {module}')
    except ImportError:
        print(f'   ❌ {module}')
"

echo ""
echo "📁 Current Directory Files:"
ls -la *.deb 2>/dev/null | head -3 || echo "   No .deb files found"

echo ""
echo "🎯 Run full check: python3 final_check_ai_hat.py"
