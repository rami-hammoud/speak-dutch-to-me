#!/bin/bash
# Play all generated voice test files on the Pi

echo "🔊 Playing Voice Test Files"
echo "================================"

PI_HOST="${PI_HOST:-voice-assistant}"
PI_USER="${PI_USER:-rami}"

echo "📡 Connecting to $PI_USER@$PI_HOST..."
echo ""

ssh -t "$PI_USER@$PI_HOST" bash << 'EOF'
    # Check for MP3 player
    if ! command -v mpg123 &> /dev/null; then
        echo "❌ mpg123 not found. Installing..."
        sudo apt-get update -qq && sudo apt-get install -y mpg123
    fi
    
    echo "🔊 Testing Voice System Audio"
    echo "==============================="
    echo ""
    
    cd ~/workspace/speak-dutch-to-me/pi-assistant
    
    echo "1️⃣  Playing: test_en.mp3 (English test)"
    mpg123 -q test_en.mp3
    sleep 1
    
    echo "2️⃣  Playing: test_nl.mp3 (Dutch test)"
    mpg123 -q test_nl.mp3
    sleep 1
    
    echo ""
    echo "🇳🇱 Dutch Words:"
    echo ""
    
    echo "3️⃣  Playing: Goedemorgen (Good morning)"
    mpg123 -q dutch_word_1.mp3
    sleep 1
    
    echo "4️⃣  Playing: Dank je wel (Thank you)"
    mpg123 -q dutch_word_2.mp3
    sleep 1
    
    echo "5️⃣  Playing: Tot ziens (Goodbye)"
    mpg123 -q dutch_word_3.mp3
    sleep 1
    
    echo "6️⃣  Playing: Alstublieft (Please/Here you are)"
    mpg123 -q dutch_word_4.mp3
    sleep 1
    
    echo ""
    echo "✅ All audio tests complete!"
    echo ""
    echo "📁 Files available:"
    ls -lh *.mp3 /tmp/test_*.mp3 2>/dev/null
EOF

echo ""
echo "🎉 Audio playback test complete!"
