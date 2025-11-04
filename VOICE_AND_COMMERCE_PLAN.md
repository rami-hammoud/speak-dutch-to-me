# 🎙️ Voice Features & 🛒 Agentic Commerce Plan

## Current Status
✅ Audio manager exists with basic structure
✅ E-commerce module stub exists
✅ AI chat working (can be voice-driven)
✅ MCP framework for tool execution

---

## 🎙️ PHASE 1: Voice Features (Priority 1)

### 1.1 Voice Input (Speech-to-Text)
**Goal:** User can speak to the assistant instead of typing

**Implementation Options:**
1. **Browser Web Speech API** ⭐ RECOMMENDED
   - Native browser support
   - No server-side processing needed
   - Works in Chrome, Edge, Safari
   - Real-time recognition
   
2. **OpenAI Whisper API**
   - More accurate
   - Multi-language support
   - Costs $ per minute
   - Requires API key

3. **Local Whisper (on Pi)**
   - Completely private
   - Slower on Pi
   - No API costs
   - Complex setup

**Recommendation:** Start with Web Speech API, add Whisper as option later

**Features to implement:**
- [ ] Voice button in chat UI
- [ ] Real-time speech-to-text display
- [ ] Language selection (English/Dutch)
- [ ] Push-to-talk or continuous listening
- [ ] Visual feedback (listening indicator)
- [ ] Auto-send on pause detection

**Files to modify:**
```
pi-assistant/templates/dutch_learning.html - Add voice UI
pi-assistant/static/js/voice.js - New: Voice handling
pi-assistant/main.py - WebSocket for voice data (if needed)
```

**Effort:** 2-3 hours

---

### 1.2 Voice Output (Text-to-Speech)
**Goal:** Assistant speaks responses back to user

**Implementation Options:**
1. **Browser Web Speech API** ⭐ RECOMMENDED
   - Native browser TTS
   - Multiple voices
   - Language support
   - No backend needed

2. **Google Cloud TTS**
   - High quality
   - Costs money
   - More natural voices

3. **pyttsx3 (existing)**
   - Offline
   - Lower quality
   - Robotic sound

**Recommendation:** Web Speech API for Dutch pronunciation

**Features to implement:**
- [ ] Auto-read AI responses
- [ ] Dutch pronunciation for vocabulary
- [ ] Voice selection (male/female)
- [ ] Speed control
- [ ] "Read aloud" button for any text
- [ ] Pronunciation practice mode

**Files to modify:**
```
pi-assistant/templates/dutch_learning.html - Add TTS controls
pi-assistant/static/js/voice.js - TTS handling
pi-assistant/services/pronunciation_service.py - Dutch TTS
```

**Effort:** 2-3 hours

---

### 1.3 Voice-Activated Commands
**Goal:** Control the assistant with voice commands

**Commands:**
- "Hey assistant" - Wake word
- "Stop listening"
- "Read that again"
- "Translate to Dutch/English"
- "Save that word"
- "Show my vocabulary"
- "Take a picture"
- "Search for [product]"

**Features:**
- [ ] Command recognition
- [ ] Feedback sounds
- [ ] Command history
- [ ] Custom commands

**Effort:** 2-3 hours

---

## 🛒 PHASE 2: Agentic Commerce (Priority 2)

### 2.1 Product Search Agent
**Goal:** AI agent finds products based on natural language

**Features:**
- [ ] Natural language product search
  - "Find me a good laptop under $1000"
  - "I need hiking boots for winter"
  - "Show me the best coffee makers"

- [ ] Multi-platform search
  - Amazon
  - eBay
  - AliExpress
  - Local stores (if APIs available)

- [ ] Smart filtering
  - Price range
  - Ratings
  - Reviews
  - Shipping options
  - Return policies

- [ ] Product recommendations
  - Based on conversation
  - Compare similar products
  - "People also bought"

**APIs to integrate:**
```
- Amazon Product Advertising API
- eBay API
- Google Shopping API
- RapidAPI marketplace scrapers
```

**Files to modify:**
```
pi-assistant/mcp/modules/ecommerce.py - Implement real APIs
pi-assistant/services/shopping_service.py - New: API wrappers
pi-assistant/main.py - Shopping endpoints
pi-assistant/templates/shopping.html - New: Shopping UI
```

**Effort:** 5-6 hours

---

### 2.2 Price Comparison & Deals
**Goal:** AI finds best deals automatically

**Features:**
- [ ] Real-time price comparison
- [ ] Price history tracking
- [ ] Deal alerts
- [ ] Coupon finding
- [ ] Shipping cost calculation
- [ ] Total cost comparison

**Effort:** 3-4 hours

---

### 2.3 Purchase Assistance (Careful Implementation!)
**Goal:** AI can help complete purchases WITH user approval

**Safety features:**
- [ ] ALWAYS require explicit confirmation
- [ ] Show complete order summary
- [ ] Never store payment info
- [ ] Use platform's native checkout
- [ ] Transaction logging
- [ ] Spending limits

**Features:**
- [ ] Cart management
- [ ] Address selection
- [ ] Payment method selection
- [ ] Order review before purchase
- [ ] Multi-step confirmation
  - "Are you sure?"
  - "Confirm purchase of X for $Y"
  - "Final confirmation"

**Implementation:**
```javascript
// Example confirmation flow
1. AI: "I found Product X for $50. Add to cart?"
2. User: "Yes"
3. AI: "Added. Ready to checkout?"
4. User: "Yes"
5. AI: "Shows order summary. Confirm purchase?"
6. User: "Confirm"
7. System: Executes purchase
8. AI: "Order placed! Tracking #123"
```

**Effort:** 4-5 hours

---

### 2.4 Order Tracking
**Goal:** Track orders and get updates

**Features:**
- [ ] Order status monitoring
- [ ] Delivery estimates
- [ ] Shipping notifications
- [ ] Return assistance
- [ ] Order history

**Effort:** 2-3 hours

---

## 🎯 Implementation Roadmap

### Week 1: Core Voice Features
**Days 1-2:** Speech-to-Text (Web Speech API)
**Days 3-4:** Text-to-Speech (Dutch pronunciation)
**Day 5:** Voice commands

**Deliverable:** Voice-enabled chat interface

---

### Week 2: Shopping Agent Foundation
**Days 1-2:** Product search API integration
**Days 3-4:** Price comparison
**Day 5:** Shopping UI

**Deliverable:** Can search and compare products

---

### Week 3: Purchase Flow
**Days 1-2:** Cart management
**Days 3-4:** Checkout flow with safety
**Day 5:** Testing and refinement

**Deliverable:** Complete purchase flow

---

## 🔐 Security & Safety Considerations

### Voice Privacy
- [ ] Local processing when possible
- [ ] Clear recording indicators
- [ ] Audio data not stored
- [ ] User consent

### Commerce Safety
- [ ] Never auto-purchase without confirmation
- [ ] Spending limits ($100 default)
- [ ] Transaction logging
- [ ] Easy undo/cancel
- [ ] No payment storage
- [ ] Use OAuth for platform auth
- [ ] Encrypted credentials

---

## 💡 Innovative Features

### Voice + Commerce Integration
1. **Voice Shopping**
   - "Find me a new keyboard"
   - AI searches, shows options
   - "Tell me about option 2"
   - AI reads review summary
   - "Add it to cart"
   - "Actually, find a cheaper one"

2. **Smart Reminders**
   - "Remind me to buy coffee when I'm low"
   - Camera sees empty coffee jar
   - "You're low on coffee. Order more?"

3. **Budget Assistant**
   - "I want to buy a new laptop"
   - "Your budget is $1000 this month"
   - "Show me options under $800"

4. **Dutch Practice with Shopping**
   - Learn Dutch words while shopping
   - "How do you say 'keyboard' in Dutch?"
   - "Een toetsenbord"
   - "Want to add it to vocabulary?"

---

## 📋 Quick Start Tasks (This Week)

### Day 1: Voice Input (TODAY)
- [ ] Add microphone button to chat
- [ ] Implement Web Speech API
- [ ] Test speech recognition
- [ ] Add visual feedback

### Day 2: Voice Output
- [ ] Add TTS to responses
- [ ] Dutch pronunciation
- [ ] Voice controls

### Day 3: Shopping APIs
- [ ] Research best e-commerce APIs
- [ ] Set up API keys
- [ ] Implement basic search
- [ ] Test product retrieval

### Day 4: Shopping UI
- [ ] Product display cards
- [ ] Comparison table
- [ ] Cart interface

### Day 5: Integration
- [ ] Voice + Shopping together
- [ ] "Find me X" works end-to-end
- [ ] Testing

---

## 🚀 Which Feature First?

**My Recommendation:**
1. **Start with Voice Input (Speech-to-Text)** 
   - Immediate value
   - Enhances chat experience
   - Foundation for voice shopping
   
2. **Then Voice Output (TTS)**
   - Complete voice loop
   - Better for Dutch learning
   
3. **Then Shopping Search**
   - Core commerce feature
   - Can be voice-driven
   
4. **Finally Purchase Flow**
   - Complete the circle

**Should I start implementing Voice Input now?** 🎤
