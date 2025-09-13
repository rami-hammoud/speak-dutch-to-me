# 🇳🇱 Speak Dutch to Me - AI-Powered Dutch Learning Assistant

An interactive Dutch learning system powered by AI HAT+ (Hailo-8L) on Raspberry Pi 5, featuring Ollama for local AI inference, speech recognition, pronunciation practice, and camera-based vocabulary learning.

## 🚀 Features

- **AI-Powered Conversations**: Practice Dutch with an AI assistant using Ollama + llama3.2
- **Pronunciation Practice**: Record your voice and get feedback on Dutch pronunciation
- **Visual Learning**: Point your camera at objects to learn Dutch vocabulary
- **Translation & Grammar**: Get translations with pronunciation guides and grammar explanations
- **Optimized for AI HAT+**: Configured to work with Hailo-8L AI accelerator on Raspberry Pi 5
- **Local Privacy**: All AI processing happens locally using Ollama (no cloud required)

## 🛠️ Hardware Requirements

- **Raspberry Pi 5** (8GB recommended)
- **AI HAT+** with Hailo-8L AI accelerator
- **Camera** (Pi Camera or USB webcam)
- **Microphone** and **Speaker** (for audio practice)
- **MicroSD card** (32GB+ recommended)

## 📦 Quick Setup

### 1. Initial System Setup (First Time Only)

```bash
# Update system and install basic dependencies
sudo apt update && sudo apt upgrade -y

# Clone or download this repository
# If you haven't already, get the files to your Pi

# Make scripts executable (if not already done)
chmod +x *.sh
```

### 2. Configure AI HAT+ and Ollama

You've already completed the Ollama installation! Now optimize it:

```bash
# Configure Ollama for AI HAT+ integration
./configure_ollama_ai_hat.sh
```

### 3. Fix Audio System

```bash
# Fix audio configuration issues
./fix_audio.sh

# Test audio after running the script
python3 test_audio.py
```

### 4. Set Up Dutch Learning Assistant

```bash
# Configure the Pi Assistant for Dutch learning
cd pi-assistant
./setup_pi_assistant.sh

# Go back to main directory
cd ..

# Set up Dutch-specific features
./setup_dutch_assistant.sh
```

### 5. Start the Assistant

```bash
# Start the Dutch learning assistant
./start_dutch_assistant.sh
```

Then open your web browser to:
- **Main interface**: http://localhost:8080
- **Dutch learning interface**: http://localhost:8080/dutch

## 🎯 Current Status

Based on your setup output, you have:

✅ **Ollama installed and running** (localhost:11434)  
✅ **llama3.2 model downloaded** (2.0 GB)  
✅ **Systemd service created**  
⚠️ **Audio needs configuration** (bus connection failed)  
❓ **AI HAT+ needs optimization** (Hailo acceleration setup)

## 🔧 Troubleshooting

### Audio Issues

If you see "Failed to connect to bus: No medium found":

```bash
# Run the audio fix script
./fix_audio.sh

# If issues persist, try:
sudo reboot

# After reboot, test audio:
python3 test_audio.py
```

### Ollama Performance

```bash
# Test Ollama performance with AI HAT+ config
python3 test_ollama_performance.py

# Check Ollama status
systemctl status ollama

# View Ollama logs
journalctl -u ollama -f
```

### AI HAT+ Detection

```bash
# Check if Hailo device is detected
lspci | grep -i hailo

# Test AI HAT+ functionality
python3 test_ai_hat.py

# Quick hardware check
./quick_status.sh
```

## 📁 Project Structure

```
speak-dutch-to-me/
├── README.md                      # This file
├── setup_ai_hat.sh              # AI HAT+ hardware setup
├── test_ai_hat.py               # AI HAT+ testing script
├── configure_ollama_ai_hat.sh   # Ollama + AI HAT+ optimization
├── fix_audio.sh                 # Audio system configuration
├── setup_dutch_assistant.sh    # Dutch learning features setup
├── start_dutch_assistant.sh     # Startup script
├── quick_status.sh             # Quick system status check
├── test_ollama_performance.py  # Generated performance test
├── test_audio.py              # Generated audio test
└── pi-assistant/              # Main application
    ├── main.py               # FastAPI web server
    ├── ai_service.py        # AI provider management
    ├── config.py           # Configuration
    ├── requirements.txt    # Python dependencies
    ├── setup_pi_assistant.sh # Pi Assistant setup
    ├── templates/          # Web interface templates
    │   ├── index.html
    │   └── dutch_learning.html # Dutch learning interface
    ├── static/            # CSS, JS, images
    ├── ui/               # UI components
    └── mcp/             # Model Context Protocol
```

## 🎓 Using the Dutch Learning Assistant

### Web Interface Features

1. **Conversation Practice**
   - Choose your level (beginner/intermediate/advanced)
   - Type in English or Dutch
   - Get AI responses with corrections and encouragement

2. **Translation & Pronunciation**
   - Enter text to translate to Dutch
   - Get phonetic pronunciation guides
   - Learn grammar rules and cultural context

3. **Voice Recording**
   - Click the microphone button to record
   - Practice Dutch pronunciation
   - Get feedback on your speaking

4. **Visual Learning**
   - Use your camera to identify objects
   - Learn Dutch vocabulary for real-world items
   - Build practical vocabulary

### API Endpoints

- `GET /dutch` - Dutch learning interface
- `POST /api/dutch/conversation` - AI conversation
- `POST /api/dutch/translate` - Translation service
- `POST /api/dutch/speech` - Speech processing
- `POST /api/dutch/visual` - Visual learning
- `GET /api/status` - System status

## ⚙️ Configuration

### Ollama Settings

The system is configured to use:
- **Model**: llama3.2 (optimized for Pi 5)
- **Host**: localhost:11434
- **Max parallel requests**: 2
- **Memory optimization**: Enabled for Pi 5

### Audio Configuration

- **PulseAudio**: Configured for user session
- **ALSA**: Fallback configuration
- **Speech**: espeak for text-to-speech

### Camera Settings

- **Resolution**: 640x480 (optimized for Pi processing)
- **Format**: Compatible with Pi Camera and USB webcams

## 🔄 Next Steps After Setup

1. **Test all components**:
   ```bash
   python3 test_audio.py
   python3 test_ollama_performance.py
   ```

2. **Start learning Dutch**:
   ```bash
   ./start_dutch_assistant.sh
   ```

3. **Access the web interface**:
   - Open browser to http://your-pi-ip:8080/dutch

4. **Optional: Add OpenAI API**:
   - Edit `pi-assistant/.env`
   - Add your OpenAI API key for enhanced features

## 🤝 Contributing

This is a learning project! Feel free to:
- Add new Dutch learning features
- Improve AI HAT+ integration
- Enhance the web interface
- Add more language learning capabilities

## 📄 License

This project is for educational purposes. Check individual component licenses.

---

**Happy Dutch learning! Veel succes met het leren van Nederlands!** 🇳🇱