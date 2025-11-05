# 🇳🇱 Dutch Learning AI Assistant

A Raspberry Pi-powered AI assistant designed to help you learn Dutch through conversation, vocabulary practice, and pronunciation feedback.

## ✨ Features

- **AI Chat**: Practice Dutch conversation with an AI tutor powered by Ollama
- **Vocabulary Management**: Build and organize your Dutch vocabulary
- **Pronunciation Practice**: Record and receive feedback on your pronunciation
- **Local & Private**: All AI processing happens on your Raspberry Pi
- **Web Interface**: Easy-to-use browser-based interface

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi 4/5 (4GB+ RAM recommended)
- Raspberry Pi OS Bookworm
- Internet connection for initial setup
- Microphone (for voice commands)
- Camera (optional, for future features)

### One-Command Installation

On your Raspberry Pi, run:

```bash
curl -sSL https://raw.githubusercontent.com/rami-hammoud/speak-dutch-to-me/main/deploy.sh | bash -s -- --https
```

Or clone and deploy:

```bash
git clone https://github.com/rami-hammoud/speak-dutch-to-me.git
cd speak-dutch-to-me
./deploy.sh --https
```

That's it! The script will:
- ✅ Install all dependencies (ffmpeg, FLAC, Python packages)
- ✅ Setup Python virtual environment
- ✅ Generate SSL certificates for HTTPS
- ✅ Configure systemd service
- ✅ Start Pi Assistant automatically

### Access the Web Interface

```
https://YOUR_PI_IP:8080/voice-chat
```

Click "Advanced" → "Proceed" to bypass the self-signed certificate warning.

**📚 Full Documentation:** See [DEPLOY.md](DEPLOY.md) for detailed deployment options and troubleshooting.

## 📋 Project Structure

```
speak-dutch-to-me/
├── README.md                    # This file
├── MILESTONES.md               # Project milestones and progress
├── setup_trixie.sh             # One-command setup script
└── pi-assistant/               # Main application
    ├── main.py                 # Flask web application
    ├── config.py               # Configuration
    ├── ai_service.py           # AI/Ollama integration
    ├── requirements.txt        # Python dependencies
    ├── start_assistant.sh      # Start the application
    ├── load_seed_data.py       # Database initialization
    ├── data/                   # Vocabulary and seed data
    ├── mcp/                    # Model Context Protocol modules
    ├── services/               # Translation & pronunciation services
    ├── ui/                     # Audio & camera managers
    ├── templates/              # HTML templates
    └── static/                 # CSS and static assets
```

## 🎯 Milestones

This project follows a focused, milestone-based approach. See [MILESTONES.md](MILESTONES.md) for detailed progress tracking.

### Current Status: Milestone 1 - Clean Deployment Foundation ✅

**Next Up: Milestone 2 - Core Dutch Learning Features**

1. ✅ **Milestone 1**: Clean Deployment Foundation
   - One-command setup on fresh Raspberry Pi
   - Reliable, minimal workspace

2. 🔄 **Milestone 2**: Core Dutch Learning Features
   - AI chat for Dutch practice
   - Vocabulary management (CRUD)
   - Basic pronunciation feedback

3. 📅 **Milestone 3**: Professional UI & Camera Integration
   - Modern, polished interface
   - Camera integration ("point and learn")
   - Progress tracking and achievements

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the `pi-assistant/` directory:

```bash
# Copy the example file
cd pi-assistant
cp .env.example .env

# Edit with your settings
nano .env
```

Key settings:
- `OLLAMA_HOST`: Ollama API endpoint (default: http://localhost:11434)
- `OLLAMA_MODEL`: Model to use (default: llama3.2:3b)
- `DATABASE_PATH`: SQLite database location
- `PORT`: Web server port (default: 8080)

### Ollama Models

Recommended models for Dutch learning:
- `llama3.2:3b` (default, good balance)
- `llama3.2:1b` (lighter, faster on Pi 4)
- `mistral:7b` (better quality, requires Pi 5 with 8GB)

Switch models:
```bash
# Download a new model
ollama pull llama3.2:1b

# Update .env file
echo "OLLAMA_MODEL=llama3.2:1b" >> pi-assistant/.env
```

## 🐛 Troubleshooting

### Setup Issues

**"Permission denied" when running setup script**:
```bash
chmod +x setup_trixie.sh
```

**Ollama fails to install**:
- Ensure you're on Debian Trixie (testing)
- Check internet connection
- Try manual installation: `curl -fsSL https://ollama.com/install.sh | sh`

**Python environment issues**:
```bash
# Recreate virtual environment
cd pi-assistant
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Runtime Issues

**Web interface not accessible**:
- Check if the service is running: `ps aux | grep main.py`
- Verify the port: `sudo netstat -tulpn | grep 8080`
- Check firewall rules

**Ollama not responding**:
```bash
# Check Ollama service
systemctl status ollama

# Restart Ollama
sudo systemctl restart ollama

# Test Ollama
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:3b","prompt":"test"}'
```

**Database errors**:
```bash
# Reinitialize database
cd pi-assistant
rm -f assistant.db
python3 load_seed_data.py
```

## 🤝 Contributing

This is a personal learning project, but suggestions and feedback are welcome!

## 📝 License

MIT License - Feel free to use and modify for your own learning.

## 🙏 Acknowledgments

- Built for Raspberry Pi running Debian Trixie
- Powered by [Ollama](https://ollama.ai/) for local LLM inference
- Inspired by the desire to learn Dutch effectively

---

**Ready to start learning Dutch? Run the setup and let's go! 🚀**
