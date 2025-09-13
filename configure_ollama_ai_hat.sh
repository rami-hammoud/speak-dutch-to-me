#!/bin/bash

# Configure Ollama for AI HAT+ on Raspberry Pi 5
# This script optimizes Ollama settings for use with the Hailo-8L AI accelerator

set -e

echo "🚀 Configuring Ollama for AI HAT+ Integration"
echo "============================================="

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

# Check if Ollama is installed and running
print_status "Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    print_error "Ollama is not installed or not in PATH"
    exit 1
fi

if ! systemctl is-active --quiet ollama; then
    print_warning "Ollama service is not running, starting it..."
    sudo systemctl start ollama
    sleep 5
fi

print_success "Ollama is installed and running"

# Check if AI HAT+ (Hailo) is detected
print_status "Checking for Hailo AI accelerator..."
if lspci 2>/dev/null | grep -i hailo; then
    print_success "Hailo device detected!"
    HAILO_DETECTED=true
else
    print_warning "Hailo device not detected. Configuring for CPU-only mode."
    HAILO_DETECTED=false
fi

# Create Ollama configuration directory
print_status "Creating Ollama configuration..."
OLLAMA_CONFIG_DIR="/etc/ollama"
sudo mkdir -p "$OLLAMA_CONFIG_DIR"

# Create environment configuration for Ollama
print_status "Configuring Ollama environment variables..."
sudo tee "$OLLAMA_CONFIG_DIR/ollama.env" > /dev/null << EOF
# Ollama Configuration for Raspberry Pi 5 with AI HAT+

# Memory settings optimized for Pi 5 with 8GB RAM
OLLAMA_MAX_LOADED_MODELS=2
OLLAMA_NUM_PARALLEL=2
OLLAMA_MAX_QUEUE=10

# CPU settings for ARM64
OLLAMA_NUM_THREADS=4

# Network settings
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*

# Logging
OLLAMA_DEBUG=false
OLLAMA_VERBOSE=false

EOF

if [ "$HAILO_DETECTED" = true ]; then
    print_status "Adding Hailo-specific optimizations..."
    sudo tee -a "$OLLAMA_CONFIG_DIR/ollama.env" > /dev/null << EOF
# Hailo AI HAT+ specific settings
# Note: Direct Hailo acceleration may not be supported by Ollama yet
# These settings optimize for the Pi 5 hardware when Hailo is present

# Enable hardware acceleration hints
OLLAMA_CUDA_VISIBLE_DEVICES=""
OLLAMA_HIP_VISIBLE_DEVICES=""

# Memory management with Hailo present
OLLAMA_MAX_VRAM=2048

EOF
else
    print_status "Adding CPU-only optimizations..."
    sudo tee -a "$OLLAMA_CONFIG_DIR/ollama.env" > /dev/null << EOF
# CPU-only configuration for Raspberry Pi 5
OLLAMA_MAX_VRAM=1024

EOF
fi

# Update systemd service to use the configuration
print_status "Updating Ollama systemd service..."
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << EOF
[Service]
EnvironmentFile=-/etc/ollama/ollama.env
EOF

# Create the override directory if it doesn't exist
sudo mkdir -p /etc/systemd/system/ollama.service.d/

# Reload and restart Ollama
print_status "Reloading Ollama service..."
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Wait for service to be ready
sleep 10

# Test Ollama with the configuration
print_status "Testing Ollama configuration..."
if ollama list | grep -q llama3.2; then
    print_success "llama3.2 model is available"
else
    print_warning "llama3.2 model not found, pulling it..."
    ollama pull llama3.2
fi

# Test a simple query
print_status "Testing Ollama response..."
if ollama run llama3.2 "Hello, respond with just 'OK' if you're working." | grep -q "OK"; then
    print_success "Ollama is responding correctly!"
else
    print_warning "Ollama test didn't return expected response"
fi

# Update Pi Assistant configuration to use optimized Ollama
print_status "Updating Pi Assistant configuration..."
PI_ASSISTANT_ENV="./pi-assistant/.env"
if [ -f "$PI_ASSISTANT_ENV" ]; then
    # Update existing config
    sed -i 's|OLLAMA_HOST=.*|OLLAMA_HOST=http://localhost:11434|' "$PI_ASSISTANT_ENV"
    sed -i 's|OLLAMA_MODEL=.*|OLLAMA_MODEL=llama3.2|' "$PI_ASSISTANT_ENV"
    print_success "Updated Pi Assistant configuration"
else
    print_warning "Pi Assistant .env file not found. You may need to run the Pi Assistant setup first."
fi

# Create a performance test script
print_status "Creating performance test script..."
cat > test_ollama_performance.py << 'EOF'
#!/usr/bin/env python3
"""
Test Ollama performance with AI HAT+ configuration
"""

import asyncio
import time
import aiohttp
import json

async def test_ollama_performance():
    """Test Ollama response times and quality"""
    
    test_queries = [
        "What is 2+2?",
        "Explain photosynthesis in one sentence.",
        "Translate 'Hello, how are you?' to Dutch.",
    ]
    
    print("🧪 Testing Ollama Performance")
    print("=" * 40)
    
    async with aiohttp.ClientSession() as session:
        for i, query in enumerate(test_queries, 1):
            print(f"\nTest {i}: {query}")
            
            start_time = time.time()
            
            payload = {
                "model": "llama3.2",
                "messages": [{"role": "user", "content": query}],
                "stream": False
            }
            
            try:
                async with session.post(
                    "http://localhost:11434/api/chat",
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=30)
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        end_time = time.time()
                        
                        response_time = end_time - start_time
                        content = result.get("message", {}).get("content", "No response")
                        
                        print(f"Response time: {response_time:.2f} seconds")
                        print(f"Response: {content[:100]}{'...' if len(content) > 100 else ''}")
                        
                        # Performance rating
                        if response_time < 5:
                            print("⚡ Excellent performance!")
                        elif response_time < 10:
                            print("✅ Good performance")
                        elif response_time < 20:
                            print("⚠️  Acceptable performance")
                        else:
                            print("🐌 Slow performance - consider optimization")
                    else:
                        print(f"❌ Error: HTTP {response.status}")
                        
            except asyncio.TimeoutError:
                print("❌ Request timed out")
            except Exception as e:
                print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_ollama_performance())
EOF

chmod +x test_ollama_performance.py

print_success "Configuration complete!"
print_status "Ollama is now optimized for your Raspberry Pi 5 setup"

if [ "$HAILO_DETECTED" = true ]; then
    print_warning "Note: While Hailo hardware is detected, Ollama doesn't currently support"
    print_warning "direct Hailo acceleration. The configuration optimizes for Pi 5 + Hailo coexistence."
    print_status "For Hailo acceleration, you'll need to use Hailo-specific inference engines."
fi

echo ""
print_status "You can now:"
echo "1. Test performance: python3 test_ollama_performance.py"
echo "2. Check Ollama status: systemctl status ollama"
echo "3. View Ollama logs: journalctl -u ollama -f"
echo "4. Test with curl: curl http://localhost:11434/api/generate -d '{\"model\":\"llama3.2\",\"prompt\":\"Hello\"}'"
echo ""
print_success "Ollama is ready for use with your Pi Assistant!"
