# Pi Assistant

A comprehensive AI assistant for Raspberry Pi with AI Hat, featuring a touch-friendly web interface, voice interaction, camera integration, and system control capabilities.

## Features

### 🤖 Dual AI Provider Support
- **OpenAI Integration**: Connect to GPT-4 and other OpenAI models
- **Local Ollama Support**: Run AI models locally for privacy and offline use
- **Seamless Switching**: Toggle between providers via the web interface

### 🖱️ Touch-Friendly Web UI
- **Responsive Design**: Optimized for touch screens (800x480 and larger)
- **Real-time Chat**: WebSocket-based streaming chat interface
- **Visual Status Indicators**: Monitor AI, camera, and audio status
- **Quick Commands**: One-click system operations

### 🎤 Audio Capabilities
- **Voice Input**: Speech-to-text using multiple recognition engines
- **Text-to-Speech**: Convert AI responses to speech
- **Multiple Audio Sources**: Support for USB microphones and Pi audio
- **Real-time Processing**: Live audio streaming and processing

### 📷 Camera Integration
- **Pi Camera Support**: Native support for Raspberry Pi camera modules
- **USB Camera Fallback**: Works with standard USB cameras
- **Live Streaming**: Real-time camera feed in the web interface
- **Computer Vision**: Face detection and basic image analysis
- **Photo Capture**: Take photos via web interface or voice commands

### 🔧 System Control (MCP Server)
- **Hardware Control**: GPIO pin control and monitoring
- **System Information**: CPU, memory, disk, and temperature monitoring
- **Process Management**: View and manage running processes
- **File System**: Browse and read files
- **Network Status**: Monitor connectivity and interfaces
- **Service Control**: Start, stop, and monitor system services

## Hardware Requirements

### Minimum Setup
- Raspberry Pi 4 or 5
- MicroSD card (32GB+ recommended)
- Power supply (USB-C for Pi 5, Micro-USB for Pi 4)

### Recommended Setup (as described in your setup)
- **Raspberry Pi 5**
- **AI HAT** (for enhanced AI processing)
- **SSD via USB 3.0** (for better performance)
- **Touch Display** (800x480 or larger)
- **AI Camera Module** (or USB camera)
- **Speakers via DigAmp+** (or USB speakers)
- **USB Microphone**
- **SmartiPi Case Touch Pro 3**
- **USB-C + DC Power Supply**

### Optional Enhancements
- **M.2 SSD via PCIe** (with HAT and splitter)
- **Better microphone** (for improved voice recognition)
- **Dedicated power supply** (to replace USB-C power)

## Installation

### Quick Setup

1. **Clone or download** the project to your Raspberry Pi
2. **Run the setup script**:
   ```bash
   chmod +x setup_pi_assistant.sh
   ./setup_pi_assistant.sh
   ```
3. **Start the assistant**:
   ```bash
   chmod +x start_assistant.sh
   ./start_assistant.sh
   ```

### Manual Installation

1. **Update system**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install system dependencies**:
   ```bash
   sudo apt install -y python3 python3-pip python3-venv build-essential \
   cmake pkg-config libjpeg-dev libpng-dev portaudio19-dev alsa-utils \
   libcamera-apps python3-libcamera espeak espeak-data
   ```

3. **Create virtual environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

4. **Install Python packages**:
   ```bash
   pip install -r requirements.txt
   ```

5. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env file with your settings
   ```

## Configuration

### Environment Variables

Edit the `.env` file to configure your assistant:

```bash
# Server settings
HOST=0.0.0.0
PORT=8080
DEBUG=true

# OpenAI settings
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4

# Ollama settings (for local AI)
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2

# Camera settings
CAMERA_ENABLED=true
CAMERA_WIDTH=640
CAMERA_HEIGHT=480

# Display settings
FULLSCREEN=false
SCREEN_WIDTH=800
SCREEN_HEIGHT=480
```

### Ollama Setup (Local AI)

For privacy and offline use, install Ollama:

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
sudo systemctl enable ollama
sudo systemctl start ollama

# Pull a model (this may take several minutes)
ollama pull llama3.2
```

## Usage

### Web Interface

1. **Access the interface**: Navigate to `http://your-pi-ip:8080`
2. **Choose AI provider**: Toggle between OpenAI and Ollama
3. **Chat with the assistant**: Type messages or use voice input
4. **Monitor camera feed**: View live camera stream
5. **Execute quick commands**: Use buttons for system operations

### Voice Interaction

1. **Click the microphone button** or press and hold
2. **Speak your message** clearly
3. **Release the button** to process speech
4. **The transcription** will appear in the text input

### System Commands

Use the MCP server for system operations:

- **System Info**: Get CPU, memory, disk usage, temperature
- **Camera Capture**: Take photos via camera
- **Network Status**: Check connectivity and IP addresses
- **GPIO Control**: Control Raspberry Pi GPIO pins
- **File Operations**: Browse and read files
- **Process Management**: Monitor running processes

## API Reference

### REST Endpoints

- `GET /` - Web interface
- `POST /api/chat` - Send chat message
- `POST /api/provider` - Change AI provider
- `GET /api/providers` - List available providers
- `POST /api/audio/start` - Start audio recording
- `POST /api/audio/stop` - Stop recording and get transcription
- `GET /api/camera/frame` - Get current camera frame

### WebSocket Events

- `chat` - Send streaming chat message
- `audio_data` - Send audio data for processing
- `system_command` - Execute MCP system command

## Running as a Service

### Install as System Service

```bash
sudo systemctl enable pi-assistant
sudo systemctl start pi-assistant
```

### Monitor Service

```bash
# Check status
sudo systemctl status pi-assistant

# View logs
sudo journalctl -u pi-assistant -f

# Restart service
sudo systemctl restart pi-assistant
```

## Development

### Project Structure

```
pi-assistant/
├── main.py                 # Main application
├── config.py              # Configuration management
├── ai_service.py          # AI provider management
├── requirements.txt       # Python dependencies
├── setup_pi_assistant.sh  # Installation script
├── start_assistant.sh     # Startup script
├── mcp/
│   └── server.py         # MCP server implementation
├── ui/
│   ├── audio_manager.py   # Audio input/output
│   └── camera_manager.py  # Camera operations
├── templates/
│   └── index.html        # Web interface
├── static/               # Static assets
├── data/                 # Application data
└── logs/                 # Log files
```

### Adding New MCP Tools

1. **Extend the MCP server** in `mcp/server.py`
2. **Register the tool** in the `_register_tools()` method
3. **Implement the handler** function
4. **Add UI controls** in `templates/index.html`

### Customizing the UI

- **Modify templates** in `templates/`
- **Add static assets** in `static/`
- **Update CSS styles** in the HTML template
- **Add JavaScript functionality** for new features

## Troubleshooting

### Common Issues

1. **Camera not working**:
   ```bash
   # Enable camera interface
   sudo raspi-config nonint do_camera 0
   
   # Check camera detection
   libcamera-hello --list-cameras
   ```

2. **Audio not working**:
   ```bash
   # Check audio devices
   arecord -l
   aplay -l
   
   # Test microphone
   arecord -d 5 test.wav
   aplay test.wav
   ```

3. **Permission issues**:
   ```bash
   # Add user to audio group
   sudo usermod -a -G audio $USER
   
   # Fix GPIO permissions
   sudo usermod -a -G gpio $USER
   ```

4. **Python package issues**:
   ```bash
   # Reinstall in virtual environment
   source venv/bin/activate
   pip install --force-reinstall -r requirements.txt
   ```

### Performance Optimization

1. **Use SSD**: Boot from SSD instead of microSD
2. **Increase GPU memory**: Add `gpu_mem=128` to `/boot/config.txt`
3. **Optimize camera**: Reduce resolution/framerate if needed
4. **Monitor resources**: Use system info to check CPU/memory usage

### Logs and Debugging

```bash
# Application logs
tail -f logs/assistant.log

# System service logs
sudo journalctl -u pi-assistant -f

# Enable debug mode
# Set DEBUG=true in .env file
```

## License

This project is open source. Feel free to modify and distribute according to your needs.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on Raspberry Pi hardware
5. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section
- Review the logs for error messages
- Ensure all hardware is properly connected
- Verify all dependencies are installed

---

**Enjoy your AI-powered Raspberry Pi assistant! 🤖🥧**
