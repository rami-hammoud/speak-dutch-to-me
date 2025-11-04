# 🚀 Development Roadmap - Next Features

## Current Status (Nov 1, 2025)
✅ Camera working with correct colors (IMX500 AI HAT+)
✅ AI chat working with Ollama (llama3.2:3b)
✅ Basic infrastructure and MCP framework in place
✅ Deployment automation (deploy_to_pi.sh)

---

## 🎯 Priority Features to Build

### 1. **Enhanced Chat with Dutch Focus** ⭐ HIGH PRIORITY
**Why:** Make the chat specifically useful for learning Dutch

**Features:**
- Add Dutch tutor system prompt
- Context-aware conversation (remembers what you're learning)
- Automatic translation toggle (Dutch ↔ English)
- Grammar correction in chat
- Vocabulary suggestions during conversation
- Chat history persistence

**Files to modify:**
- `ai_service.py` - Add Dutch tutor prompt
- `main.py` - Add chat history storage
- Frontend - Add translation toggle, grammar hints

**Effort:** 2-3 hours

---

### 2. **Vocabulary Management UI** ⭐ HIGH PRIORITY
**Why:** Core feature for learning - users need to manage their vocabulary

**Features:**
- View vocabulary list with search/filter
- Add new words manually
- Edit/delete words
- Categories and tags
- Progress indicators (learned/learning/new)
- Export/import vocabulary

**Files to create/modify:**
- Frontend component for vocabulary table
- API endpoints already exist in `main.py`
- Database queries in `dutch_learning.py`

**Effort:** 3-4 hours

---

### 3. **Pronunciation Practice** ⭐ MEDIUM PRIORITY
**Why:** Essential for language learning

**Features:**
- Record audio in browser
- Text-to-speech for Dutch words
- Pronunciation scoring
- Visual feedback on accuracy
- Practice sessions

**Files to modify:**
- `services/pronunciation_service.py` - Already exists, needs integration
- Frontend - Add audio recording
- Add Web Speech API or MediaRecorder

**Effort:** 4-5 hours

---

### 4. **Camera-Based Visual Learning** ⭐ MEDIUM PRIORITY
**Why:** Unique feature - point at objects to learn Dutch words

**Features:**
- Live camera preview (already working!)
- Click/tap to identify objects
- Show Dutch word + article + pronunciation
- Save to vocabulary
- Quiz mode with camera

**Files to modify:**
- Frontend - Add object detection UI
- `camera_manager.py` - Add object detection
- `dutch_learning.py` - Already has object_vocabulary mapping!

**Effort:** 4-5 hours

---

### 5. **Progress Dashboard** ⭐ LOW PRIORITY
**Why:** Motivational, helps users track learning

**Features:**
- Words learned this week
- Current streak
- Level progress (A1, A2, etc.)
- Daily challenges completed
- Study time tracking

**Files to modify:**
- Frontend dashboard (already partially exists)
- MCP tools already support progress tracking

**Effort:** 2-3 hours

---

### 6. **Grammar Exercises** ⭐ LOW PRIORITY
**Why:** Complement vocabulary learning

**Features:**
- Articles (de/het) practice
- Verb conjugation
- Sentence building
- Multiple choice quizzes
- Progress tracking

**Files to modify:**
- Frontend exercise interface
- MCP tools already exist for grammar

**Effort:** 3-4 hours

---

## 🎨 UI/UX Improvements (Ongoing)

- Modern, responsive design
- Loading states
- Error handling
- Toast notifications
- Smooth animations
- Dark/light mode toggle
- Mobile optimization

---

## 🤔 Which Feature Should We Build First?

**My Recommendation: Start with #1 (Enhanced Chat) + #2 (Vocabulary Management)**

**Why?**
1. Chat is working but basic - make it Dutch-specific
2. Vocabulary management is essential for any language learning app
3. These two work together (chat suggests words → save to vocabulary)
4. Foundation for other features

**Timeline:** Can complete both in 5-7 hours

---

## 📋 Quick Wins (15-30 min each)

- [ ] Add Dutch flag emoji to UI
- [ ] Add "Speak Dutch to me!" tagline
- [ ] Add example phrases on home page
- [ ] Add keyboard shortcuts (Enter to send, etc.)
- [ ] Add word of the day
- [ ] Add fun Dutch facts/tips

Would you like me to start with the Enhanced Dutch Chat feature?
