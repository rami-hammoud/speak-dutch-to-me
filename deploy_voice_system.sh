#!/bin/bash
# Deploy and test voice system on Raspberry Pi

set -e

echo "🚀 Deploying Voice System to Raspberry Pi..."
echo "=" * 60

# SSH connection details
PI_HOST="${PI_HOST:-voice-assistant}"
PI_USER="${PI_USER:-rami}"
PI_PROJECT_DIR="/home/rami/workspace/speak-dutch-to-me"

echo "📡 Connecting to $PI_USER@$PI_HOST..."

# Deploy, install, and test
ssh -t "$PI_USER@$PI_HOST" bash << 'EOF'
    set -e
    cd ~/workspace/speak-dutch-to-me
    
    echo ""
    echo "📥 Pulling latest changes..."
    git pull origin main
    
    echo ""
    echo "📦 Installing voice dependencies..."
    cd pi-assistant
    source venv/bin/activate
    
    # Install voice recognition and TTS packages
    pip install --upgrade pip
    pip install SpeechRecognition gtts pyttsx3 vosk
    
    # Install audio dependencies if not already installed
    echo ""
    echo "🔊 Checking audio system packages..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq portaudio19-dev python3-pyaudio espeak espeak-ng mpg123 sox || true
    
    # Try to install PyAudio (might fail, that's ok)
    pip install pyaudio || echo "⚠️  PyAudio install failed (ok if system package exists)"
    
    echo ""
    echo "🎤 Testing voice recognition backends..."
    python3 << 'PYTEST'
import sys
sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')

from services.voice_recognition_service import VoiceRecognitionService
import asyncio

async def test():
    service = VoiceRecognitionService()
    await service.initialize()
    
    backends = service.get_available_backends()
    print(f"\n✅ Available voice recognition backends: {', '.join(backends) if backends else 'None'}")
    
    info = service.get_backend_info()
    for name, details in info.items():
        status = "✅" if details['available'] else "❌"
        print(f"  {status} {name}: {details['type']}")
    
    return len(backends) > 0

try:
    result = asyncio.run(test())
    if result:
        print("\n🎉 Voice recognition system is working!")
    else:
        print("\n⚠️  No voice recognition backends available")
        sys.exit(1)
except Exception as e:
    print(f"\n❌ Voice recognition test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTEST
    
    echo ""
    echo "🔊 Testing text-to-speech backends..."
    python3 << 'PYTEST'
import sys
sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')

from services.tts_service import TextToSpeechService
import asyncio

async def test():
    service = TextToSpeechService()
    await service.initialize()
    
    backends = service.get_available_backends()
    print(f"\n✅ Available TTS backends: {', '.join(backends) if backends else 'None'}")
    
    info = service.get_backend_info()
    for name, details in info.items():
        status = "✅" if details['available'] else "❌"
        print(f"  {status} {name}")
    
    # Try to generate test audio
    if backends:
        print(f"\n🎵 Generating test audio with {backends[0]}...")
        audio = await service.speak("Testing one two three", language="en-US", save_to="/tmp/test_en.mp3")
        if audio:
            print(f"✅ English audio generated ({len(audio)} bytes)")
        
        audio = await service.speak("Goedemorgen", language="nl-NL", save_to="/tmp/test_nl.mp3")
        if audio:
            print(f"✅ Dutch audio generated ({len(audio)} bytes)")
    
    return len(backends) > 0

try:
    result = asyncio.run(test())
    if result:
        print("\n🎉 Text-to-speech system is working!")
    else:
        print("\n⚠️  No TTS backends available")
        sys.exit(1)
except Exception as e:
    print(f"\n❌ TTS test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTEST
    
    echo ""
    echo "🧪 Running full voice system test..."
    cd /home/rami/workspace/speak-dutch-to-me/pi-assistant
    python3 test_voice_system.py || echo "⚠️  Some tests may have failed (check output above)"
    
    echo ""
    echo "📁 Generated test files:"
    echo "  Files in /tmp:"
    ls -lh /tmp/test_*.mp3 2>/dev/null || echo "    (none)"
    echo "  Files in current directory:"
    ls -lh *.mp3 2>/dev/null || echo "    (none)"
    
    echo ""
    echo "🔊 Testing audio playback..."
    if command -v mpg123 &> /dev/null; then
        echo "  Playing test_en.mp3 with mpg123..."
        mpg123 -q /tmp/test_en.mp3 2>/dev/null && echo "  ✅ English audio played successfully!" || echo "  ⚠️  Audio playback had issues"
    elif command -v ffplay &> /dev/null; then
        echo "  Playing with ffplay..."
        ffplay -nodisp -autoexit /tmp/test_en.mp3 2>/dev/null && echo "  ✅ Audio played!" || echo "  ⚠️  Audio playback had issues"
    else
        echo "  ⚠️  No MP3 player found (install mpg123 or ffplay)"
    fi
    
    echo ""
    echo "🔄 Restarting assistant service..."
    sudo systemctl restart pi-assistant
    
    echo ""
    echo "⏳ Waiting for service to start..."
    sleep 3
    
    echo ""
    echo "📊 Service status:"
    sudo systemctl status pi-assistant --no-pager -l | head -20
    
    echo ""
    echo "✅ Voice system deployment and testing complete!"
    
EOF

echo ""
echo "🎉 Done! Voice system is deployed and tested on the Pi."
echo ""
echo "📝 To play the audio files manually:"
echo "  # Play MP3 files:"
echo "  ssh $PI_USER@$PI_HOST 'mpg123 /tmp/test_en.mp3'"
echo "  ssh $PI_USER@$PI_HOST 'mpg123 /tmp/test_nl.mp3'"
echo ""
echo "  # Or convert to WAV and use aplay:"
echo "  ssh $PI_USER@$PI_HOST 'ffmpeg -i /tmp/test_en.mp3 /tmp/test_en.wav && aplay /tmp/test_en.wav'"
echo ""
echo "📁 View all generated files:"
echo "  ssh $PI_USER@$PI_HOST 'ls -lh /tmp/test_*.mp3 ~/workspace/speak-dutch-to-me/pi-assistant/*.mp3'"
echo ""
echo "📊 View logs:"
echo "  ssh $PI_USER@$PI_HOST 'sudo journalctl -u pi-assistant -f'"
