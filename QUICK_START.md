# Quick Start Guide

## 🚀 Local Development (macOS/Linux)

### 1. Setup Environment
```bash
cd /Users/rami/workspace/speak-dutch-to-me/pi-assistant

# Create virtual environment (if not exists)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment
```bash
# Copy example config
cp .env.example .env

# Edit configuration (optional for local testing)
nano .env
```

### 3. Initialize Database
```bash
# Load seed vocabulary
python load_seed_data.py

# This creates: data/dutch_learning.db with 30 Dutch words
```

### 4. Run the Application
```bash
# Start server
uvicorn main:assistant.app --reload --host 0.0.0.0 --port 8080

# Access at: http://localhost:8080
# Dutch Learning: http://localhost:8080/dutch-learning
```

## 🍓 Raspberry Pi Deployment

### 1. Run Setup Script
```bash
# On Raspberry Pi
cd ~/workspace/speak-dutch-to-me
chmod +x setup_pi_complete.sh
./setup_pi_complete.sh

# Follow prompts, will take 15-30 minutes
```

### 2. Configure API Keys (Optional)
```bash
nano ~/workspace/speak-dutch-to-me/pi-assistant/.env

# Add any API keys:
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-...
```

### 3. Load Initial Data
```bash
cd ~/workspace/speak-dutch-to-me/pi-assistant
source venv/bin/activate
python load_seed_data.py
```

### 4. Enable & Start Services
```bash
# Enable auto-start
sudo systemctl enable pi-assistant.service
sudo systemctl enable virtual-camera.service

# Start services
sudo systemctl start pi-assistant.service
sudo systemctl start virtual-camera.service

# Check status
sudo systemctl status pi-assistant.service
```

### 5. Access Application
```bash
# Find Pi's IP
hostname -I

# Access at: http://<PI_IP>:8080
# Example: http://192.168.1.100:8080
```

## 📖 Using Dutch Learning

### Web Interface
1. Navigate to `/dutch-learning`
2. Choose a learning mode:
   - **Flashcards**: Review vocabulary with spaced repetition
   - **Exercises**: Practice grammar (articles, verbs, word order)
   - **Conversation**: Chat in Dutch with AI feedback

### Flashcard Mode
- Click card to flip (Dutch ↔ English)
- Rate difficulty: Hard 😰 or Easy 😊
- Track progress with progress bar
- View streak and stats at top

### Exercise Mode
- Answer multiple choice questions
- Get instant feedback
- See explanations for mistakes
- Progress through difficulty levels

### Conversation Mode
- Type responses in Dutch
- Click 🎤 for speech input (browser support required)
- Submit for AI feedback
- Practice real conversations

## 🛠️ Development Tasks

### Add New Vocabulary
```bash
# Method 1: Via Web UI
# Navigate to /dutch-learning, use "Add Word" feature

# Method 2: Programmatically
python -c "
from mcp.modules.dutch_learning import DutchLearningModule
import asyncio

async def add_word():
    module = DutchLearningModule()
    await module.initialize()
    result = await module._add_vocabulary({
        'dutch_word': 'fiets',
        'english_translation': 'bicycle',
        'category': 'travel',
        'level': 'A1',
        'pronunciation': 'FEETS',
        'example_sentence': 'Ik rijd op mijn fiets.'
    })
    print(result)

asyncio.run(add_word())
"
```

### Test Translation Service
```bash
python -c "
from services.translation_service import TranslationService
import asyncio

async def test():
    service = TranslationService()
    result = await service.translate('Hello, how are you?', 'english', 'dutch')
    print(result)

asyncio.run(test())
"
```

### Test Pronunciation Scoring
```bash
# Requires audio file
python -c "
from services.pronunciation_service import PronunciationScorer
import asyncio
import base64

async def test():
    scorer = PronunciationScorer()
    # Load your audio file as base64
    with open('test_audio.wav', 'rb') as f:
        audio_b64 = base64.b64encode(f.read()).decode()
    
    result = await scorer.score_pronunciation(
        target_text='hallo',
        audio_data=audio_b64,
        language='nl-NL'
    )
    print(result)

asyncio.run(test())
"
```

## 🔧 Troubleshooting

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill it
kill -9 <PID>

# Or use different port
uvicorn main:assistant.app --port 8081
```

### Database Issues
```bash
# Reset database
rm data/dutch_learning.db
python load_seed_data.py
```

### Module Import Errors
```bash
# Ensure in correct directory
cd pi-assistant

# Activate venv
source venv/bin/activate

# Check Python path
python -c "import sys; print('\n'.join(sys.path))"
```

### Virtual Camera Not Working (Pi)
```bash
# Check if loaded
lsmod | grep v4l2loopback

# Load manually
sudo modprobe v4l2loopback devices=1 video_nr=10

# Check video devices
ls -la /dev/video*
```

### Audio Not Working (Pi)
```bash
# List audio devices
aplay -l
arecord -l

# Test PulseAudio
pactl info

# Restart audio
systemctl --user restart pulseaudio
```

## 📝 Useful Commands

### View Logs
```bash
# Service logs
sudo journalctl -u pi-assistant -f

# Application logs
tail -f logs/assistant.log
```

### Database Queries
```bash
sqlite3 data/dutch_learning.db

# Count vocabulary
SELECT COUNT(*) FROM vocabulary;

# Show recent words
SELECT dutch_word, english_translation, added_date 
FROM vocabulary 
ORDER BY added_date DESC 
LIMIT 10;

# Check progress
SELECT * FROM daily_progress 
ORDER BY date DESC 
LIMIT 7;
```

### Git Operations
```bash
# Check status
git status

# View recent commits
git log --oneline -n 10

# Pull latest changes
git pull origin main

# Create feature branch
git checkout -b feature/new-feature
```

## 🎯 Next Development Steps

1. **Test Locally** ✅ (Ready)
   ```bash
   cd pi-assistant
   source venv/bin/activate
   uvicorn main:assistant.app --reload
   ```

2. **Deploy to Pi** (Ready)
   ```bash
   ./setup_pi_complete.sh
   ```

3. **Add Audio Recording UI**
   - Edit `templates/dutch_learning.html`
   - Add MediaRecorder API integration
   - Connect to pronunciation scoring endpoint

4. **Implement Personal Assistant APIs**
   - Google Calendar OAuth
   - Todoist API integration
   - Add to `mcp/modules/personal_assistant.py`

5. **Implement E-Commerce APIs**
   - Amazon Product API
   - eBay SDK
   - Add to `mcp/modules/ecommerce.py`

## 📚 Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **Ollama**: https://ollama.ai/
- **MCP Protocol**: (Internal documentation)
- **Dutch Grammar**: https://www.dutchgrammar.com/
- **CEFR Levels**: https://www.coe.int/en/web/common-european-framework-reference-languages

## 🆘 Getting Help

1. Check logs: `sudo journalctl -u pi-assistant -f`
2. Review CHANGELOG.md for recent changes
3. Check DEVELOPMENT_SUMMARY.md for architecture
4. Read module READMEs in `mcp/modules/`

---

**Last Updated**: 2025-10-23  
**Version**: 0.2.0  
**Status**: ✅ Ready for Testing
