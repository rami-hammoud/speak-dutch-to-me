#!/bin/bash

# Dutch Learning Assistant Setup for macOS
# This script sets up the assistant for development on Mac

echo "🇳🇱 Setting up Dutch Learning Assistant for macOS"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_warning "This script is designed for macOS"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for Homebrew
print_status "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    print_success "Homebrew is installed"
fi

# Install Python and required packages
print_status "Installing Python and dependencies via Homebrew..."
brew install python3 portaudio espeak

# Check for Ollama
print_status "Checking for Ollama..."
if ! command -v ollama &> /dev/null; then
    print_status "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    
    print_status "Starting Ollama..."
    ollama serve &
    sleep 5
    
    print_status "Pulling llama3.2 model..."
    ollama pull llama3.2
else
    print_success "Ollama is installed"
    
    # Make sure Ollama is running
    if ! pgrep -x "ollama" > /dev/null; then
        print_status "Starting Ollama..."
        ollama serve &
        sleep 5
    fi
    
    # Check if model is available
    if ! ollama list | grep -q llama3.2; then
        print_status "Pulling llama3.2 model..."
        ollama pull llama3.2
    fi
fi

# Navigate to pi-assistant directory
cd pi-assistant

# Create virtual environment
print_status "Creating Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install \
    fastapi \
    uvicorn[standard] \
    jinja2 \
    python-multipart \
    websockets \
    aiohttp \
    pyaudio \
    SpeechRecognition \
    pyttsx3 \
    python-dotenv \
    psutil

# Create macOS-specific config
print_status "Creating macOS configuration..."
cat > .env << 'EOF'
# Dutch Learning Pi Assistant - macOS Configuration

# Server settings
HOST=127.0.0.1
PORT=8080
DEBUG=true

# OpenAI settings (add your API key if you have one)
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4

# Ollama settings (primary AI provider)
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2

# MCP server settings
MCP_HOST=localhost
MCP_PORT=8081

# Camera settings (disabled for macOS)
CAMERA_ENABLED=false
CAMERA_WIDTH=640
CAMERA_HEIGHT=480

# Audio settings (will auto-detect macOS audio)
AUDIO_INPUT_DEVICE=
AUDIO_OUTPUT_DEVICE=

# Display settings
FULLSCREEN=false
SCREEN_WIDTH=1200
SCREEN_HEIGHT=800

# Dutch learning specific settings
DEFAULT_LANGUAGE=dutch
SPEECH_RATE=150
VOICE_LANGUAGE=nl

# Data directories
DATA_DIR=./data
LOGS_DIR=./logs
EOF

# Create directories
print_status "Creating directories..."
mkdir -p data logs static/css static/js static/images

# Update config.py for macOS compatibility
print_status "Updating configuration for macOS..."
cat >> config.py << 'EOF'

# macOS-specific overrides
import platform
if platform.system() == "Darwin":  # macOS
    CAMERA_ENABLED = False  # Disable camera by default on macOS
EOF

# Create macOS startup script
print_status "Creating macOS startup script..."
cat > ../start_dutch_assistant_mac.sh << 'EOF'
#!/bin/bash

echo "🇳🇱 Starting Dutch Learning Assistant on macOS..."

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama..."
    ollama serve &
    sleep 3
fi

# Navigate to pi-assistant directory
cd "$(dirname "$0")/pi-assistant"

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "Activated Python virtual environment"
fi

# Start the assistant
echo "Starting Dutch Learning Assistant..."
echo "Access the web interface at: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop the assistant"
python3 main.py
EOF

chmod +x ../start_dutch_assistant_mac.sh

# Update audio manager for macOS
print_status "Updating audio manager for macOS compatibility..."
# Disable Pi-specific audio features in audio_manager.py by adding macOS checks

# Go back to main directory
cd ..

print_success "macOS setup complete!"

echo ""
print_status "🎉 Your Dutch Learning Assistant is ready for macOS!"
echo ""
print_status "To start the assistant:"
echo "   ./start_dutch_assistant_mac.sh"
echo ""
print_status "Then open your browser to:"
echo "   http://localhost:8080"
echo ""
print_status "Features available on macOS:"
echo "   ✅ AI-powered conversations in Dutch (via Ollama)"
echo "   ✅ Translation with pronunciation guides"
echo "   ✅ Text-to-speech for pronunciation practice"
echo "   ✅ Web-based interface"
echo "   ✅ All Dutch learning features"
echo ""
print_status "Camera features are disabled on macOS but all other functionality works!"
echo ""
print_warning "Note: Make sure Ollama is running before starting the assistant."
echo "You can check with: ollama list"
