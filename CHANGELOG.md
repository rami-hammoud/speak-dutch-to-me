# Changelog

All notable changes to the Dutch Learning AI Assistant project.

## [Unreleased] - 2025-10-23

### Added - Dutch Learning Module
- **Complete Dutch Learning System** with MCP architecture
  - Vocabulary management with spaced repetition algorithm
  - Grammar explanations and interactive exercises
  - Multi-provider translation service (LibreTranslate, Ollama, Dictionary)
  - Pronunciation scoring using speech recognition
  - Camera-based visual learning (object-to-Dutch mapping)
  - Progress tracking with daily stats and streak system
  - Conversation practice sessions
  - Daily learning challenges

- **Database Schema** for Dutch learning
  - `vocabulary` table: words, translations, mastery scores
  - `practice_sessions` table: session tracking
  - `daily_progress` table: streak and stats tracking
  - `grammar_progress` table: topic mastery

- **Seed Vocabulary Data**
  - 30 common Dutch words across categories (greetings, food, colors, numbers)
  - Includes pronunciation guides and example sentences
  - A1-A2 CEFR level coverage

- **Dutch Learning Web UI** (`templates/dutch_learning.html`)
  - Beautiful gradient UI with glassmorphism effects
  - Three learning modes: Flashcards, Exercises, Conversation
  - Real-time stats dashboard (streak, vocabulary count, mastery)
  - Interactive flashcards with flip animation
  - Grammar exercises with instant feedback
  - Conversation practice with speech recognition
  - Vocabulary browser with mastery indicators
  - Daily challenge display
  - Fully responsive design

- **API Endpoints** for Dutch learning
  - `GET /dutch-learning` - Learning interface
  - `GET /api/dutch/stats` - Progress statistics
  - `GET /api/dutch/review-words` - Spaced repetition words
  - `GET /api/dutch/vocabulary` - Search vocabulary
  - `POST /api/dutch/vocabulary` - Add new words
  - `GET /api/dutch/exercises` - Grammar exercises
  - `POST /api/dutch/conversation/start` - Start conversation
  - `GET /api/dutch/daily-challenge` - Get daily challenge
  - `POST /api/dutch/translate` - Translate text

- **Translation Service** (`services/translation_service.py`)
  - Multi-provider fallback system
  - LibreTranslate integration (self-hosted option)
  - Ollama LLM-based translation (offline option)
  - Dictionary lookup fallback (always available)
  - In-memory caching for performance
  - Pronunciation guide generation

- **Pronunciation Service** (`services/pronunciation_service.py`)
  - Speech-to-text using Google Speech Recognition
  - Sphinx offline recognition fallback
  - Similarity scoring with word overlap analysis
  - Detailed feedback and pronunciation tips
  - Word-by-word comparison
  - Rating system (excellent, good, fair, needs work)

- **MCP Module Structure**
  - `mcp/modules/dutch_learning.py` - Full implementation
  - `mcp/modules/personal_assistant.py` - Scaffolded
  - `mcp/modules/ecommerce.py` - Scaffolded
  - `mcp/modules/__init__.py` - Module registry
  - `mcp/modules/README.md` - Module documentation

### Added - Infrastructure
- **Complete Pi Setup Script** (`setup_pi_complete.sh`)
  - System package installation
  - Raspberry Pi hardware support (camera, audio)
  - v4l2loopback virtual camera setup
  - Ollama local LLM installation
  - Python virtual environment setup
  - MCP server structure creation
  - Audio system configuration (PulseAudio + ALSA)
  - Systemd service creation for auto-start
  - Environment configuration templates

- **Data Loading Script** (`load_seed_data.py`)
  - Loads seed vocabulary into database
  - Checks for existing data
  - Supports custom database and seed file paths
  - Creates database schema if needed

- **Services Package** (`services/__init__.py`)
  - Proper Python package structure
  - Exports TranslationService and PronunciationScorer

### Changed
- **main.py** - Added Dutch learning API endpoints
- **requirements.txt** - Added dependencies:
  - aiohttp (HTTP client for translation)
  - SpeechRecognition (pronunciation scoring)
  - opencv-python (camera/vision)
  - numpy (data processing)

### Technical Details
- **MCP Tools**: 14 tools for Dutch learning
  - dutch_vocabulary_search
  - dutch_vocabulary_add
  - dutch_vocabulary_review
  - dutch_grammar_explain
  - dutch_grammar_exercise
  - dutch_translate
  - dutch_pronunciation_guide
  - dutch_pronunciation_score
  - dutch_conversation_practice
  - dutch_daily_challenge
  - dutch_progress_stats
  - dutch_streak_info
  - dutch_camera_identify

- **Visual Learning**: Object detection with color-based demo
  - Placeholder for YOLO/MobileNet integration
  - 50+ common objects mapped to Dutch vocabulary
  - Article (de/het) and pronunciation included

- **Grammar Topics**: Articles, verb conjugation, word order
- **Exercise Difficulty**: Easy, medium, hard
- **CEFR Levels**: A1, A2, B1, B2, C1, C2

### Next Steps
- Test Dutch learning module end-to-end
- Integrate real object detection (YOLO/MobileNet)
- Implement personal assistant API integrations (Google Calendar, Todoist)
- Implement e-commerce API integrations (Amazon, eBay)
- Add audio recording UI for pronunciation practice
- Enhanced error handling and user feedback
- Deploy to Raspberry Pi and test hardware integration
- Add unit tests for all modules
- Documentation for end users

### Dependencies
- Python 3.9+
- FastAPI, uvicorn
- SQLite3
- aiohttp (optional, for translation)
- SpeechRecognition (optional, for pronunciation)
- opencv-python (optional, for visual learning)
- Ollama (optional, for local LLM)

### Platform Support
- Raspberry Pi 4/5 (primary)
- Raspberry Pi AI HAT+ camera
- ReSpeaker microphone (optional)
- Any Linux system (partial support)
- macOS/Windows (development only)

## [0.1.0] - 2025-10-XX

### Added
- Initial project setup
- Basic Pi Assistant structure
- Config and AI service foundation
- Audio and camera managers
- UI templates (index.html)

---

**Legend:**
- Added: New features
- Changed: Changes to existing functionality
- Deprecated: Soon-to-be removed features
- Removed: Removed features
- Fixed: Bug fixes
- Security: Security improvements
