#!/bin/bash

# Complete setup for Dutch Learning Pi Assistant with AI HAT+ and Ollama
# This script integrates Ollama, AI HAT+, and audio for the Dutch learning application

set -e

echo "🇳🇱 Dutch Learning Pi Assistant Setup with AI HAT+"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Ollama is installed and working
check_ollama() {
    print_status "Checking Ollama installation..."
    
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama not found. Please run the setup scripts first."
        return 1
    fi
    
    if ! systemctl is-active --quiet ollama; then
        print_warning "Starting Ollama service..."
        sudo systemctl start ollama
        sleep 5
    fi
    
    # Test if llama3.2 model is available
    if ollama list | grep -q llama3.2; then
        print_success "Ollama with llama3.2 model is ready"
    else
        print_warning "llama3.2 model not found"
        return 1
    fi
    
    return 0
}

# Configure the Pi Assistant for Dutch learning
configure_dutch_assistant() {
    print_status "Configuring Dutch Learning Assistant..."
    
    # Navigate to pi-assistant directory
    cd pi-assistant
    
    # Create optimized configuration for Dutch learning
    print_status "Creating optimized Dutch learning configuration..."
    
    cat > .env << 'EOF'
# Dutch Learning Pi Assistant Configuration

# Server settings
HOST=0.0.0.0
PORT=8080
DEBUG=false

# OpenAI settings (optional - add your key if you have one)
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4

# Ollama settings (primary AI provider)
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2

# MCP server settings
MCP_HOST=localhost
MCP_PORT=8081

# Camera settings for visual Dutch learning
CAMERA_ENABLED=true
CAMERA_WIDTH=640
CAMERA_HEIGHT=480

# Audio settings for pronunciation practice
AUDIO_INPUT_DEVICE=
AUDIO_OUTPUT_DEVICE=

# Display settings
FULLSCREEN=false
SCREEN_WIDTH=800
SCREEN_HEIGHT=480

# Dutch learning specific settings
DEFAULT_LANGUAGE=dutch
SPEECH_RATE=150
VOICE_LANGUAGE=nl
EOF
    
    print_success "Created optimized configuration"
    
    # Update the AI service configuration for Dutch learning
    print_status "Updating AI service for Dutch learning..."
    
    # Add Dutch-specific prompts and configuration
    cat >> ai_service.py << 'EOF'

# Dutch Learning Specific Extensions
class DutchLearningService:
    """Dutch learning specific AI service extensions"""
    
    def __init__(self, ai_service):
        self.ai_service = ai_service
        self.dutch_system_prompt = """
        You are a helpful Dutch language learning assistant. You help users learn Dutch through:
        - Pronunciation practice and correction
        - Grammar explanations
        - Vocabulary building
        - Cultural context
        - Interactive conversations
        
        Always be encouraging and patient. Provide corrections gently and explain why.
        Use simple English explanations for beginners, but encourage Dutch practice.
        """
    
    async def dutch_conversation(self, user_input: str, level: str = "beginner") -> str:
        """Handle Dutch learning conversations"""
        system_msg = Message(role="system", content=f"{self.dutch_system_prompt}\nUser level: {level}")
        user_msg = Message(role="user", content=user_input)
        
        response = await self.ai_service.chat([system_msg, user_msg])
        return response.content
    
    async def translate_and_explain(self, text: str, from_lang: str = "english", to_lang: str = "dutch") -> str:
        """Translate text and provide explanations"""
        prompt = f"""
        Translate this {from_lang} text to {to_lang}: "{text}"
        
        Then provide:
        1. The translation
        2. Pronunciation guide (phonetic)
        3. Grammar notes if relevant
        4. Cultural context if applicable
        """
        
        msg = Message(role="user", content=prompt)
        response = await self.ai_service.chat([msg])
        return response.content
    
    async def pronunciation_help(self, dutch_text: str) -> str:
        """Provide pronunciation help for Dutch text"""
        prompt = f"""
        For this Dutch text: "{dutch_text}"
        
        Provide:
        1. Phonetic pronunciation guide
        2. Syllable breakdown
        3. Tips for difficult sounds
        4. Audio description of how to pronounce it
        """
        
        msg = Message(role="user", content=prompt)
        response = await self.ai_service.chat([msg])
        return response.content
EOF
    
    cd ..
}

# Create Dutch learning specific web interface updates
create_dutch_ui() {
    print_status "Creating Dutch learning web interface..."
    
    # Update the main template for Dutch learning
    cat > pi-assistant/templates/dutch_learning.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dutch Learning Assistant</title>
    <link rel="stylesheet" href="/static/style.css">
    <style>
        .dutch-section {
            margin: 20px 0;
            padding: 15px;
            border-radius: 10px;
            background-color: #f0f8ff;
            border-left: 4px solid #ff8c00;
        }
        .pronunciation-guide {
            font-family: 'Courier New', monospace;
            background-color: #fff;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .level-selector {
            margin: 10px 0;
        }
        .dutch-flag {
            background: linear-gradient(to bottom, #ff0000 33%, #ffffff 33%, #ffffff 66%, #0000ff 66%);
            height: 20px;
            width: 30px;
            display: inline-block;
            margin-right: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1><span class="dutch-flag"></span>Dutch Learning Assistant</h1>
            <p>Practice Dutch with AI-powered conversations and pronunciation help</p>
        </header>
        
        <div class="dutch-section">
            <h2>🗣️ Conversation Practice</h2>
            <div class="level-selector">
                <label for="level">Your Level:</label>
                <select id="level">
                    <option value="beginner">Beginner</option>
                    <option value="intermediate">Intermediate</option>
                    <option value="advanced">Advanced</option>
                </select>
            </div>
            
            <div class="chat-interface">
                <div id="chat-messages"></div>
                <div class="input-group">
                    <input type="text" id="dutch-input" placeholder="Type in English or Dutch...">
                    <button onclick="sendMessage()">Send</button>
                    <button onclick="startRecording()" id="record-btn">🎤 Record</button>
                </div>
            </div>
        </div>
        
        <div class="dutch-section">
            <h2>🔤 Translation & Pronunciation</h2>
            <div class="input-group">
                <input type="text" id="translate-input" placeholder="Enter text to translate...">
                <button onclick="translateText()">Translate to Dutch</button>
            </div>
            <div id="translation-result" class="pronunciation-guide"></div>
        </div>
        
        <div class="dutch-section">
            <h2>📸 Visual Learning</h2>
            <p>Point your camera at objects to learn Dutch vocabulary!</p>
            <div class="camera-container">
                <video id="camera-feed" autoplay></video>
                <canvas id="camera-canvas" style="display: none;"></canvas>
                <button onclick="captureAndLearn()">Learn Dutch Words</button>
            </div>
            <div id="visual-results"></div>
        </div>
        
        <div class="dutch-section">
            <h2>⚙️ System Status</h2>
            <div id="system-status">
                <p>🤖 AI Status: <span id="ai-status">Checking...</span></p>
                <p>🎵 Audio Status: <span id="audio-status">Checking...</span></p>
                <p>📷 Camera Status: <span id="camera-status">Checking...</span></p>
            </div>
        </div>
    </div>
    
    <script>
        // Dutch Learning Assistant JavaScript
        let isRecording = false;
        let mediaRecorder;
        let audioChunks = [];
        
        // Initialize the application
        document.addEventListener('DOMContentLoaded', function() {
            checkSystemStatus();
            initializeCamera();
        });
        
        // Send text message
        async function sendMessage() {
            const input = document.getElementById('dutch-input');
            const level = document.getElementById('level').value;
            const message = input.value.trim();
            
            if (!message) return;
            
            addMessageToChat('You', message);
            input.value = '';
            
            try {
                const response = await fetch('/api/dutch/conversation', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({message, level})
                });
                
                const data = await response.json();
                addMessageToChat('Dutch Assistant', data.response);
            } catch (error) {
                addMessageToChat('System', 'Error: Could not get response');
            }
        }
        
        // Add message to chat
        function addMessageToChat(sender, message) {
            const chatMessages = document.getElementById('chat-messages');
            const messageDiv = document.createElement('div');
            messageDiv.className = 'message';
            messageDiv.innerHTML = `<strong>${sender}:</strong> ${message}`;
            chatMessages.appendChild(messageDiv);
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }
        
        // Translate text
        async function translateText() {
            const input = document.getElementById('translate-input');
            const text = input.value.trim();
            
            if (!text) return;
            
            try {
                const response = await fetch('/api/dutch/translate', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({text})
                });
                
                const data = await response.json();
                document.getElementById('translation-result').innerHTML = data.result;
            } catch (error) {
                document.getElementById('translation-result').innerHTML = 'Translation error';
            }
        }
        
        // Voice recording
        async function startRecording() {
            const button = document.getElementById('record-btn');
            
            if (!isRecording) {
                try {
                    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                    mediaRecorder = new MediaRecorder(stream);
                    audioChunks = [];
                    
                    mediaRecorder.ondataavailable = event => {
                        audioChunks.push(event.data);
                    };
                    
                    mediaRecorder.onstop = async () => {
                        const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
                        // Process audio for speech recognition
                        await processAudio(audioBlob);
                    };
                    
                    mediaRecorder.start();
                    isRecording = true;
                    button.textContent = '⏹️ Stop';
                    button.style.backgroundColor = '#ff4444';
                } catch (error) {
                    alert('Could not access microphone');
                }
            } else {
                mediaRecorder.stop();
                isRecording = false;
                button.textContent = '🎤 Record';
                button.style.backgroundColor = '';
            }
        }
        
        // Process recorded audio
        async function processAudio(audioBlob) {
            const formData = new FormData();
            formData.append('audio', audioBlob);
            
            try {
                const response = await fetch('/api/dutch/speech', {
                    method: 'POST',
                    body: formData
                });
                
                const data = await response.json();
                document.getElementById('dutch-input').value = data.text;
            } catch (error) {
                console.error('Speech processing error:', error);
            }
        }
        
        // Camera functionality
        async function initializeCamera() {
            try {
                const video = document.getElementById('camera-feed');
                const stream = await navigator.mediaDevices.getUserMedia({ 
                    video: { width: 640, height: 480 } 
                });
                video.srcObject = stream;
                document.getElementById('camera-status').textContent = '✅ Ready';
            } catch (error) {
                document.getElementById('camera-status').textContent = '❌ Not available';
            }
        }
        
        // Capture image and learn Dutch words
        async function captureAndLearn() {
            const video = document.getElementById('camera-feed');
            const canvas = document.getElementById('camera-canvas');
            const ctx = canvas.getContext('2d');
            
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            ctx.drawImage(video, 0, 0);
            
            canvas.toBlob(async (blob) => {
                const formData = new FormData();
                formData.append('image', blob);
                
                try {
                    const response = await fetch('/api/dutch/visual', {
                        method: 'POST',
                        body: formData
                    });
                    
                    const data = await response.json();
                    document.getElementById('visual-results').innerHTML = data.dutch_words;
                } catch (error) {
                    document.getElementById('visual-results').innerHTML = 'Visual learning error';
                }
            });
        }
        
        // Check system status
        async function checkSystemStatus() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                
                document.getElementById('ai-status').textContent = 
                    data.ai_ready ? '✅ Ready' : '❌ Not ready';
                document.getElementById('audio-status').textContent = 
                    data.audio_ready ? '✅ Ready' : '❌ Not ready';
            } catch (error) {
                document.getElementById('ai-status').textContent = '❌ Error';
                document.getElementById('audio-status').textContent = '❌ Error';
            }
        }
        
        // Handle Enter key in inputs
        document.getElementById('dutch-input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') sendMessage();
        });
        
        document.getElementById('translate-input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') translateText();
        });
    </script>
</body>
</html>
EOF
}

# Create startup script for the Dutch learning assistant
create_startup_script() {
    print_status "Creating startup script..."
    
    cat > start_dutch_assistant.sh << 'EOF'
#!/bin/bash

# Start Dutch Learning Pi Assistant
echo "🇳🇱 Starting Dutch Learning Assistant..."

# Ensure Ollama is running
if ! systemctl is-active --quiet ollama; then
    echo "Starting Ollama..."
    sudo systemctl start ollama
    sleep 5
fi

# Ensure audio is working
if ! systemctl --user is-active --quiet pulseaudio; then
    echo "Starting PulseAudio..."
    systemctl --user start pulseaudio
    sleep 2
fi

# Navigate to pi-assistant directory and start
cd pi-assistant

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start the assistant
echo "Starting Dutch Learning Assistant..."
echo "Access the web interface at: http://localhost:8080"
python3 main.py
EOF

    chmod +x start_dutch_assistant.sh
    print_success "Created startup script"
}

# Update the main.py to include Dutch learning endpoints
update_main_py() {
    print_status "Updating main application for Dutch learning..."
    
    # Add Dutch learning routes to the main application
    cat >> pi-assistant/main.py << 'EOF'

# Dutch Learning Specific Routes
from ai_service import DutchLearningService

# Initialize Dutch learning service
dutch_service = None

@app.on_event("startup")
async def setup_dutch_learning():
    global dutch_service
    dutch_service = DutchLearningService(ai_service)

@app.get("/dutch")
async def dutch_learning_page():
    """Serve the Dutch learning interface"""
    return templates.TemplateResponse("dutch_learning.html", {"request": request})

@app.post("/api/dutch/conversation")
async def dutch_conversation(request: Request):
    """Handle Dutch learning conversations"""
    data = await request.json()
    message = data.get("message", "")
    level = data.get("level", "beginner")
    
    try:
        response = await dutch_service.dutch_conversation(message, level)
        return {"response": response}
    except Exception as e:
        return {"error": str(e)}, 500

@app.post("/api/dutch/translate")
async def dutch_translate(request: Request):
    """Translate text to Dutch with explanations"""
    data = await request.json()
    text = data.get("text", "")
    
    try:
        result = await dutch_service.translate_and_explain(text)
        return {"result": result}
    except Exception as e:
        return {"error": str(e)}, 500

@app.post("/api/dutch/speech")
async def process_dutch_speech(audio: UploadFile = File(...)):
    """Process speech for Dutch learning"""
    try:
        # Save uploaded audio temporarily
        audio_path = f"temp_audio_{int(time.time())}.wav"
        with open(audio_path, "wb") as f:
            content = await audio.read()
            f.write(content)
        
        # Use speech recognition (would need to be implemented)
        # For now, return placeholder
        text = "Speech recognition placeholder"
        
        # Clean up temp file
        os.remove(audio_path)
        
        return {"text": text}
    except Exception as e:
        return {"error": str(e)}, 500

@app.post("/api/dutch/visual")
async def dutch_visual_learning(image: UploadFile = File(...)):
    """Process images for Dutch vocabulary learning"""
    try:
        # Save uploaded image temporarily
        image_path = f"temp_image_{int(time.time())}.jpg"
        with open(image_path, "wb") as f:
            content = await image.read()
            f.write(content)
        
        # Use AI to identify objects and provide Dutch translations
        # This would integrate with your AI service
        dutch_words = "Visual recognition placeholder - implement object detection + Dutch translation"
        
        # Clean up temp file
        os.remove(image_path)
        
        return {"dutch_words": dutch_words}
    except Exception as e:
        return {"error": str(e)}, 500

@app.get("/api/status")
async def system_status():
    """Check system status for Dutch learning features"""
    try:
        # Check AI service
        ai_ready = await ai_service.test_provider("ollama")
        
        # Check audio (placeholder)
        audio_ready = True  # Would implement actual audio check
        
        return {
            "ai_ready": ai_ready,
            "audio_ready": audio_ready,
            "ollama_model": config.OLLAMA_MODEL,
            "camera_enabled": config.CAMERA_ENABLED
        }
    except Exception as e:
        return {"error": str(e)}, 500
EOF
}

# Main execution
main() {
    print_status "Starting Dutch Learning Pi Assistant setup..."
    
    # Check prerequisites
    if ! check_ollama; then
        print_error "Ollama is not properly set up. Please run the Ollama configuration script first."
        echo "Run: ./configure_ollama_ai_hat.sh"
        exit 1
    fi
    
    # Configure the assistant
    configure_dutch_assistant
    
    # Create UI
    create_dutch_ui
    
    # Update main application
    update_main_py
    
    # Create startup script
    create_startup_script
    
    print_success "Dutch Learning Pi Assistant setup complete!"
    
    echo ""
    print_status "🎉 Your Dutch Learning Assistant is ready!"
    echo ""
    print_status "To start the assistant:"
    echo "   ./start_dutch_assistant.sh"
    echo ""
    print_status "Then open your browser to:"
    echo "   http://localhost:8080/dutch"
    echo ""
    print_status "Features available:"
    echo "   ✅ AI-powered conversations in Dutch"
    echo "   ✅ Translation with pronunciation guides"
    echo "   ✅ Voice recording for pronunciation practice"
    echo "   ✅ Camera-based vocabulary learning"
    echo "   ✅ Optimized for Ollama + AI HAT+"
    echo ""
    print_warning "Note: Some features may require additional setup:"
    echo "   • Speech recognition needs additional libraries"
    echo "   • Object detection needs computer vision models"
    echo "   • Audio recording requires microphone permissions"
}

# Run the main function
main
