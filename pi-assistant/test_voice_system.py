#!/usr/bin/env python3
"""
Test script for the reusable voice recognition and TTS services
"""

import asyncio
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from services.voice_recognition_service import VoiceRecognitionService
from services.tts_service import TextToSpeechService


async def test_voice_recognition():
    """Test voice recognition backends"""
    print("\n🎙️ Testing Voice Recognition Service...")
    print("=" * 60)
    
    # Initialize service
    service = VoiceRecognitionService()
    await service.initialize(
        whisper_api_key=os.getenv("OPENAI_API_KEY"),
        vosk_model_path="/opt/vosk-models/vosk-model-small-en-us-0.15",
        preferred_backend="google"
    )
    
    # Show available backends
    backends = service.get_available_backends()
    print(f"\n✅ Available backends: {', '.join(backends)}")
    
    # Show backend info
    info = service.get_backend_info()
    print("\n📊 Backend Information:")
    for name, details in info.items():
        status = "✅ Available" if details['available'] else "❌ Not available"
        print(f"  {name}: {status} ({details['type']})")
    
    # Test with a sample audio file (if exists)
    test_file = "test_audio.wav"
    if Path(test_file).exists():
        print(f"\n🎤 Testing recognition with {test_file}...")
        result = await service.recognize_from_file(test_file, language="en-US")
        if result:
            print(f"✅ Recognized: {result}")
        else:
            print("❌ Recognition failed")
    else:
        print(f"\n⚠️  No test audio file found ({test_file})")
        print("   Create a test WAV file to test recognition")
    
    print("\n✅ Voice recognition service test complete!")


async def test_tts():
    """Test text-to-speech backends"""
    print("\n🔊 Testing Text-to-Speech Service...")
    print("=" * 60)
    
    # Initialize service
    service = TextToSpeechService()
    await service.initialize(
        openai_api_key=os.getenv("OPENAI_API_KEY"),
        preferred_backend="google"
    )
    
    # Show available backends
    backends = service.get_available_backends()
    print(f"\n✅ Available backends: {', '.join(backends)}")
    
    # Show backend info
    info = service.get_backend_info()
    print("\n📊 Backend Information:")
    for name, details in info.items():
        status = "✅ Available" if details['available'] else "❌ Not available"
        print(f"  {name}: {status}")
        if details['voices']:
            print(f"    Voices: {len(details['voices'])} available")
    
    # Test English TTS
    print("\n🗣️  Generating English speech...")
    audio = await service.speak(
        "Hello! This is a test of the text to speech system.",
        language="en-US",
        save_to="test_en.mp3"
    )
    if audio:
        print(f"✅ English audio generated: test_en.mp3 ({len(audio)} bytes)")
    else:
        print("❌ English TTS failed")
    
    # Test Dutch TTS
    print("\n🗣️  Generating Dutch speech...")
    audio = await service.speak(
        "Goedemorgen! Dit is een test van het tekst naar spraak systeem.",
        language="nl-NL",
        save_to="test_nl.mp3"
    )
    if audio:
        print(f"✅ Dutch audio generated: test_nl.mp3 ({len(audio)} bytes)")
    else:
        print("❌ Dutch TTS failed")
    
    # Show available voices
    voices = service.get_voices()
    if voices:
        print(f"\n🎵 Available voices ({len(voices)}):")
        for voice in voices[:5]:  # Show first 5
            print(f"  - {voice['name']} ({voice.get('backend', 'unknown')})")
        if len(voices) > 5:
            print(f"  ... and {len(voices) - 5} more")
    
    print("\n✅ Text-to-speech service test complete!")


async def test_complete_loop():
    """Test complete voice input -> output loop"""
    print("\n🔄 Testing Complete Voice Loop...")
    print("=" * 60)
    
    # Initialize both services
    print("\n🎤 Initializing voice recognition...")
    voice_rec = VoiceRecognitionService()
    await voice_rec.initialize(
        whisper_api_key=os.getenv("OPENAI_API_KEY"),
        preferred_backend="google"
    )
    
    print("🔊 Initializing text-to-speech...")
    tts = TextToSpeechService()
    await tts.initialize(
        openai_api_key=os.getenv("OPENAI_API_KEY"),
        preferred_backend="google"
    )
    
    # Simulate voice loop
    print("\n🎬 Simulating voice conversation...")
    
    # Simulate user input (in real app, this would be recorded audio)
    test_phrases = [
        "Hello, how are you?",
        "What's the weather like?",
        "Tell me a joke"
    ]
    
    for phrase in test_phrases:
        print(f"\n👤 User (simulated): '{phrase}'")
        
        # In real app: audio = await record_audio()
        # For now: simulate recognition result
        recognized = phrase
        print(f"🎤 Recognized: '{recognized}'")
        
        # Generate response (in real app, this would go to AI)
        response = f"You said: {recognized}"
        print(f"🤖 Response: '{response}'")
        
        # Generate speech
        audio = await tts.speak(response, language="en-US")
        if audio:
            print(f"🔊 Speech generated ({len(audio)} bytes)")
        else:
            print("❌ Speech generation failed")
    
    print("\n✅ Voice loop test complete!")


async def test_dutch_pronunciation():
    """Test Dutch pronunciation practice"""
    print("\n🇳🇱 Testing Dutch Pronunciation Practice...")
    print("=" * 60)
    
    # Initialize TTS for Dutch
    tts = TextToSpeechService()
    await tts.initialize(preferred_backend="google")
    
    # Dutch words for practice
    words = [
        {"dutch": "Goedemorgen", "english": "Good morning"},
        {"dutch": "Dank je wel", "english": "Thank you"},
        {"dutch": "Tot ziens", "english": "Goodbye"},
        {"dutch": "Alstublieft", "english": "Please/Here you are"},
    ]
    
    print("\n📚 Generating pronunciation examples...")
    for i, word in enumerate(words, 1):
        print(f"\n{i}. {word['dutch']} ({word['english']})")
        audio = await tts.speak(
            word['dutch'],
            language="nl-NL",
            save_to=f"dutch_word_{i}.mp3"
        )
        if audio:
            print(f"   ✅ Audio saved: dutch_word_{i}.mp3")
        else:
            print(f"   ❌ Failed to generate audio")
    
    print("\n✅ Dutch pronunciation test complete!")


async def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("🎙️  VOICE SYSTEM TEST SUITE")
    print("=" * 60)
    
    try:
        # Test voice recognition
        await test_voice_recognition()
        
        # Test TTS
        await test_tts()
        
        # Test complete loop
        await test_complete_loop()
        
        # Test Dutch pronunciation
        await test_dutch_pronunciation()
        
        print("\n" + "=" * 60)
        print("🎉 ALL TESTS COMPLETE!")
        print("=" * 60)
        print("\n📁 Generated files:")
        for file in ["test_en.mp3", "test_nl.mp3", "dutch_word_1.mp3", "dutch_word_2.mp3", "dutch_word_3.mp3", "dutch_word_4.mp3"]:
            if Path(file).exists():
                size = Path(file).stat().st_size
                print(f"  ✅ {file} ({size} bytes)")
        
        print("\n💡 Next steps:")
        print("  1. Play the generated MP3 files to test audio quality")
        print("  2. Create a test_audio.wav file to test voice recognition")
        print("  3. Integrate into your application!")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
