# 🎤 Reusable Voice System Documentation

## Overview
This is a **production-ready, reusable voice recognition and TTS system** that can be used in any Python project.

## Features
✅ **Multiple backends** with automatic fallback  
✅ **Async/await support** for non-blocking operations  
✅ **Language support** (English, Dutch, and 100+ languages)  
✅ **Online and offline** options  
✅ **Easy to integrate** into any project  
✅ **Well-documented** with examples  

---

## 🎙️ Voice Recognition Service

### Supported Backends

| Backend | Quality | Speed | Offline | Cost | Best For |
|---------|---------|-------|---------|------|----------|
| **Whisper** (OpenAI) | ⭐⭐⭐⭐⭐ | Fast | ❌ | $0.006/min | Production, multi-language |
| **Vosk** | ⭐⭐⭐ | Very Fast | ✅ | Free | Offline, Pi projects |
| **Google** | ⭐⭐⭐⭐ | Fast | ❌ | Free | General use |
| **Web Speech API** | ⭐⭐⭐ | Real-time | ❌ | Free | Browser apps |

### Installation

```bash
# Basic (Google Speech)
pip install SpeechRecognition

# Whisper (Best accuracy)
pip install openai

# Vosk (Offline)
pip install vosk
# Download model: https://alphacephei.com/vosk/models
wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip -d /opt/vosk-models/

# Dutch model
wget https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip
```

### Basic Usage

```python
from services.voice_recognition_service import VoiceRecognitionService

# Initialize service
service = VoiceRecognitionService()
await service.initialize(
    whisper_api_key="sk-...",  # Optional
    vosk_model_path="/opt/vosk-models/vosk-model-small-en-us-0.15",  # Optional
    preferred_backend="whisper"  # or "vosk", "google"
)

# Recognize from audio bytes
text = await service.recognize(audio_bytes, language="en-US")
print(f"You said: {text}")

# Recognize from file
text = await service.recognize_from_file("recording.wav", language="nl-NL")
print(f"Dutch text: {text}")

# Get available backends
backends = service.get_available_backends()
print(f"Available: {backends}")
```

### Advanced Usage

```python
# Try specific backend
text = await service.recognize(
    audio_bytes,
    language="nl-NL",
    backend="vosk"  # Force Vosk
)

# Streaming recognition
async def audio_stream():
    # Your audio stream generator
    for chunk in audio_chunks:
        yield chunk

service.set_callbacks(
    on_interim_result=lambda text: print(f"Interim: {text}"),
    on_final_result=lambda text: print(f"Final: {text}"),
    on_error=lambda err: print(f"Error: {err}")
)

await service.recognize_stream(audio_stream(), language="en-US")

# Get backend info
info = service.get_backend_info()
print(json.dumps(info, indent=2))
```

---

## 🔊 Text-to-Speech Service

### Supported Backends

| Backend | Quality | Speed | Offline | Cost | Best For |
|---------|---------|-------|---------|------|----------|
| **OpenAI TTS** | ⭐⭐⭐⭐⭐ | Fast | ❌ | $15/1M chars | Production, natural voices |
| **Google TTS** | ⭐⭐⭐⭐ | Fast | ❌ | Free | General use, many languages |
| **pyttsx3** | ⭐⭐ | Very Fast | ✅ | Free | Offline, Pi projects |
| **Web Speech API** | ⭐⭐⭐ | Real-time | ❌ | Free | Browser apps |

### Installation

```bash
# Basic (pyttsx3)
pip install pyttsx3

# Google TTS
pip install gtts

# OpenAI TTS (Best quality)
pip install openai

# For playback
pip install pygame  # or pyaudio
```

### Basic Usage

```python
from services.tts_service import TextToSpeechService

# Initialize service
service = TextToSpeechService()
await service.initialize(
    openai_api_key="sk-...",  # Optional
    preferred_backend="google"  # or "openai", "pyttsx3"
)

# Generate speech
audio_bytes = await service.speak("Hello, how are you?", language="en-US")

# Save to file
await service.speak(
    "Goedemorgen, hoe gaat het?",
    language="nl-NL",
    save_to="greeting.mp3"
)

# Get available voices
voices = service.get_voices()
for voice in voices:
    print(f"{voice['name']} ({voice['backend']})")

# Use specific voice
await service.speak(
    "Hello in a different voice",
    backend="openai",
    voice="nova"
)
```

### Advanced Usage

```python
# Force specific backend
audio = await service.speak(
    "Offline speech",
    backend="pyttsx3",
    language="en-US"
)

# Get all backend info
info = service.get_backend_info()

# Set default voice
service.set_voice("nova")
```

---

## 🔄 Complete Voice Loop Example

```python
from services.voice_recognition_service import VoiceRecognitionService
from services.tts_service import TextToSpeechService

# Initialize both services
voice_rec = VoiceRecognitionService()
await voice_rec.initialize(whisper_api_key="sk-...")

tts = TextToSpeechService()
await tts.initialize(openai_api_key="sk-...")

# Voice conversation loop
while True:
    # Listen
    await tts.speak("I'm listening...", save_to="listening.mp3")
    audio_input = await record_audio()  # Your recording function
    
    # Recognize
    text = await voice_rec.recognize(audio_input, language="en-US")
    print(f"You said: {text}")
    
    # Process (e.g., with AI)
    response = await ai_chat(text)
    
    # Speak response
    await tts.speak(response, language="en-US", save_to="response.mp3")
    
    if "goodbye" in text.lower():
        break
```

---

## 🇳🇱 Dutch Learning Example

```python
async def dutch_word_pronunciation_practice():
    voice_rec = VoiceRecognitionService()
    await voice_rec.initialize(preferred_backend="whisper")
    
    tts = TextToSpeechService()
    await tts.initialize(preferred_backend="google")
    
    word = "Goedemorgen"
    
    # Speak Dutch word
    print(f"Say '{word}'")
    await tts.speak(word, language="nl-NL", save_to="word.mp3")
    
    # Listen to user
    user_audio = await record_audio()
    user_text = await voice_rec.recognize(user_audio, language="nl-NL")
    
    # Compare
    if user_text.lower() == word.lower():
        await tts.speak("Perfect!", language="en-US")
    else:
        await tts.speak(f"You said {user_text}. Try again!", language="en-US")
```

---

## 🛒 Voice Shopping Example

```python
async def voice_shopping_assistant():
    voice_rec = VoiceRecognitionService()
    await voice_rec.initialize()
    
    tts = TextToSpeechService()
    await tts.initialize()
    
    await tts.speak("What would you like to buy?")
    audio = await record_audio()
    query = await voice_rec.recognize(audio)
    
    print(f"Searching for: {query}")
    products = await search_products(query)  # Your e-commerce function
    
    # Read results
    await tts.speak(f"I found {len(products)} products.")
    for i, product in enumerate(products[:3]):
        await tts.speak(
            f"Option {i+1}: {product['name']} for ${product['price']}"
        )
    
    # Get selection
    await tts.speak("Which one would you like?")
    audio = await record_audio()
    selection = await voice_rec.recognize(audio)
    
    # Process selection...
```

---

## 🏠 Smart Home Voice Control Example

```python
async def voice_controlled_assistant():
    """Example for smart home, IoT projects"""
    voice_rec = VoiceRecognitionService()
    await voice_rec.initialize(
        vosk_model_path="/opt/vosk-models/vosk-model-small-en-us-0.15",
        preferred_backend="vosk"  # Offline for privacy
    )
    
    tts = TextToSpeechService()
    await tts.initialize(preferred_backend="pyttsx3")  # Offline
    
    wake_word = "hey assistant"
    
    while True:
        audio = await listen_for_wake_word()
        text = await voice_rec.recognize(audio)
        
        if wake_word in text.lower():
            await tts.speak("Yes?")
            
            command_audio = await record_audio()
            command = await voice_rec.recognize(command_audio)
            
            # Process commands
            if "lights on" in command.lower():
                await turn_lights_on()
                await tts.speak("Lights are on")
            elif "temperature" in command.lower():
                temp = await get_temperature()
                await tts.speak(f"It's {temp} degrees")
            elif "camera" in command.lower():
                await tts.speak("Taking a picture")
                await capture_photo()
```

---

## 🔧 Integration with Your Project

### 1. Add to requirements.txt

```txt
# Voice Recognition
SpeechRecognition>=3.10.0
pyaudio>=0.2.13
openai>=1.0.0  # Optional: for Whisper
vosk>=0.3.45  # Optional: for offline

# Text-to-Speech
gtts>=2.5.0
pyttsx3>=2.90
pygame>=2.5.0  # Optional: for playback
```

### 2. Copy services to your project

```bash
cp -r pi-assistant/services/voice_recognition_service.py your-project/
cp -r pi-assistant/services/tts_service.py your-project/
```

### 3. Use in your code

```python
from voice_recognition_service import create_voice_service
from tts_service import create_tts_service

# Quick setup
voice = await create_voice_service(whisper_api_key="sk-...")
tts = await create_tts_service(openai_api_key="sk-...")

# Use anywhere
text = await voice.recognize(audio_bytes)
audio = await tts.speak(text)
```

---

## 📝 Configuration

### Environment Variables

```bash
# .env file
OPENAI_API_KEY=sk-...
VOSK_MODEL_PATH=/opt/vosk-models/vosk-model-small-en-us-0.15
PREFERRED_VOICE_BACKEND=whisper
PREFERRED_TTS_BACKEND=google
```

### Config File

```python
# config.py
class VoiceConfig:
    WHISPER_API_KEY = os.getenv("OPENAI_API_KEY")
    VOSK_MODEL_PATH = os.getenv("VOSK_MODEL_PATH", "/opt/vosk-models/vosk-model-small-en-us-0.15")
    PREFERRED_VOICE_BACKEND = os.getenv("PREFERRED_VOICE_BACKEND", "whisper")
    PREFERRED_TTS_BACKEND = os.getenv("PREFERRED_TTS_BACKEND", "google")
    DEFAULT_LANGUAGE = "en-US"
    DUTCH_LANGUAGE = "nl-NL"
```

---

## 🐛 Troubleshooting

### Voice Recognition Not Working

```python
# Check available backends
info = service.get_backend_info()
print(json.dumps(info, indent=2))

# Test each backend
for backend in ["whisper", "vosk", "google"]:
    try:
        result = await service.recognize(audio, backend=backend)
        print(f"{backend}: {result}")
    except Exception as e:
        print(f"{backend} failed: {e}")
```

### Audio Quality Issues

```python
# Ensure audio is in correct format:
# - WAV format
# - 16kHz sample rate
# - Mono channel
# - 16-bit PCM

import wave
with wave.open("audio.wav", "rb") as wf:
    print(f"Channels: {wf.getnchannels()}")
    print(f"Sample rate: {wf.getframerate()}")
    print(f"Sample width: {wf.getsampwidth()}")
```

### Vosk Model Not Found

```bash
# Download and install model
mkdir -p /opt/vosk-models
cd /opt/vosk-models
wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip
```

---

## 🚀 Performance Tips

1. **Use Vosk for low-latency** applications
2. **Use Whisper for best accuracy**
3. **Cache TTS audio** for repeated phrases
4. **Use Web Speech API** in browser for zero backend load
5. **Batch process** multiple audio files for efficiency

---

## 📚 Additional Resources

- **Whisper API**: https://platform.openai.com/docs/guides/speech-to-text
- **Vosk Models**: https://alphacephei.com/vosk/models
- **Google TTS**: https://gtts.readthedocs.io/
- **Web Speech API**: https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API

---

## 🎉 Ready to Use!

These services are **production-ready** and can be used in:
- Voice assistants
- Language learning apps
- Smart home systems
- Accessibility tools
- Customer service bots
- IoT projects
- Any project needing voice I/O

Just copy the files and integrate! 🚀
