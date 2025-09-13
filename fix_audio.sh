#!/bin/bash

# Fix audio configuration for Raspberry Pi 5 with AI HAT+
# This script resolves audio issues and configures proper audio system

set -e

echo "🔊 Fixing Audio Configuration for Raspberry Pi 5"
echo "==============================================="

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

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stop any running audio services temporarily
print_status "Stopping audio services temporarily..."
sudo systemctl stop pulseaudio.service || true
sudo pkill -f pulseaudio || true

# Install/update audio packages
print_status "Installing/updating audio packages..."
sudo apt update

# Check what packages are available and install them
AUDIO_PACKAGES="pulseaudio pulseaudio-utils alsa-utils libasound2-plugins portaudio19-dev espeak espeak-data"

# Try to install pavucontrol (GUI tool, optional)
if apt-cache show pavucontrol >/dev/null 2>&1; then
    AUDIO_PACKAGES="$AUDIO_PACKAGES pavucontrol"
fi

# Install the available packages
sudo apt install -y $AUDIO_PACKAGES

# Configure ALSA for Raspberry Pi 5
print_status "Configuring ALSA..."
sudo tee /etc/asound.conf > /dev/null << 'EOF'
# ALSA configuration for Raspberry Pi 5
pcm.!default {
    type pulse
    server "unix:/run/user/1000/pulse/native"
}

ctl.!default {
    type pulse
    server "unix:/run/user/1000/pulse/native"
}

# Fallback to hardware if PulseAudio is not available
pcm.hw {
    type hw
    card 0
    device 0
}

ctl.hw {
    type hw
    card 0
}
EOF

# Configure PulseAudio for user session
print_status "Configuring PulseAudio..."

# Create PulseAudio configuration directory
mkdir -p ~/.config/pulse

# Create PulseAudio client configuration
tee ~/.config/pulse/client.conf > /dev/null << 'EOF'
# PulseAudio client configuration
autospawn = yes
daemon-binary = /usr/bin/pulseaudio
extra-arguments = --log-target=syslog --realtime-priority=5
EOF

# Create PulseAudio daemon configuration
tee ~/.config/pulse/daemon.conf > /dev/null << 'EOF'
# PulseAudio daemon configuration
high-priority = yes
nice-level = -15
realtime-scheduling = yes
realtime-priority = 5
resample-method = speex-float-1
default-sample-format = s16le
default-sample-rate = 44100
default-sample-channels = 2
default-fragments = 4
default-fragment-size-msec = 25
EOF

# Add user to audio groups
print_status "Adding user to audio groups..."
sudo usermod -a -G audio $USER
sudo usermod -a -G pulse-access $USER

# Enable audio hardware in boot config
print_status "Enabling audio hardware..."
sudo raspi-config nonint do_audio 0

# Update boot configuration for better audio support
print_status "Updating boot configuration for audio..."
BOOT_CONFIG="/boot/firmware/config.txt"
if [ ! -f "$BOOT_CONFIG" ]; then
    BOOT_CONFIG="/boot/config.txt"
fi

# Backup original config
sudo cp "$BOOT_CONFIG" "$BOOT_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

# Add audio configuration if not present
if ! grep -q "# Audio configuration" "$BOOT_CONFIG"; then
    sudo tee -a "$BOOT_CONFIG" > /dev/null << 'EOF'

# Audio configuration
dtparam=audio=on
audio_pwm_mode=2
disable_audio_dither=1
EOF
    print_status "Added audio configuration to boot config"
fi

# Create systemd user service for PulseAudio
print_status "Creating PulseAudio user service..."
mkdir -p ~/.config/systemd/user

tee ~/.config/systemd/user/pulseaudio.service > /dev/null << 'EOF'
[Unit]
Description=PulseAudio system server
Documentation=man:pulseaudio(1)

[Service]
Type=notify
ExecStart=/usr/bin/pulseaudio --daemonize=no --system=false --disallow-exit --disallow-module-loading=false
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Enable user services
print_status "Enabling audio services..."
systemctl --user daemon-reload
systemctl --user enable pulseaudio.service

# Create audio test script
print_status "Creating audio test script..."
cat > test_audio.py << 'EOF'
#!/usr/bin/env python3
"""
Test audio system functionality
"""

import subprocess
import sys
import time
import wave
import pyaudio

def run_command(cmd):
    """Run a command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip(), True
    except subprocess.CalledProcessError as e:
        return e.stderr.strip(), False

def test_alsa():
    """Test ALSA audio system"""
    print("🔊 Testing ALSA...")
    
    # List audio devices
    output, success = run_command("aplay -l")
    if success and output:
        print("✅ ALSA devices found:")
        for line in output.split('\n'):
            if 'card' in line.lower():
                print(f"   {line}")
    else:
        print("❌ No ALSA devices found")
    
    return success

def test_pulseaudio():
    """Test PulseAudio system"""
    print("\n🎵 Testing PulseAudio...")
    
    # Check if PulseAudio is running
    output, success = run_command("pulseaudio --check")
    if success:
        print("✅ PulseAudio is running")
    else:
        print("❌ PulseAudio is not running, trying to start...")
        run_command("pulseaudio --start --daemonize")
        time.sleep(2)
    
    # List PulseAudio sinks
    output, success = run_command("pactl list short sinks")
    if success and output:
        print("✅ PulseAudio sinks:")
        for line in output.split('\n'):
            if line.strip():
                print(f"   {line}")
    else:
        print("❌ No PulseAudio sinks found")
    
    return success

def test_pyaudio():
    """Test PyAudio functionality"""
    print("\n🐍 Testing PyAudio...")
    
    try:
        import pyaudio
        
        pa = pyaudio.PyAudio()
        device_count = pa.get_device_count()
        
        print(f"✅ PyAudio initialized with {device_count} devices:")
        
        for i in range(device_count):
            info = pa.get_device_info_by_index(i)
            device_type = []
            if info['maxInputChannels'] > 0:
                device_type.append('input')
            if info['maxOutputChannels'] > 0:
                device_type.append('output')
            
            print(f"   Device {i}: {info['name']} ({'/'.join(device_type)})")
        
        pa.terminate()
        return True
        
    except ImportError:
        print("⚠️  PyAudio not installed (optional for basic functionality)")
        return True  # Don't fail the test if PyAudio is missing
    except Exception as e:
        print(f"❌ PyAudio test failed: {e}")
        return False

def test_speech():
    """Test text-to-speech"""
    print("\n🗣️  Testing text-to-speech...")
    
    try:
        # Test espeak
        output, success = run_command("espeak 'Audio test successful' --stdout | aplay")
        if success:
            print("✅ Text-to-speech (espeak) working")
            return True
        else:
            print("❌ Text-to-speech failed")
            return False
    except Exception as e:
        print(f"❌ Speech test failed: {e}")
        return False

def main():
    """Run all audio tests"""
    print("🎵 Audio System Test")
    print("=" * 30)
    
    tests = [
        ("ALSA", test_alsa),
        ("PulseAudio", test_pulseaudio),
        ("PyAudio", test_pyaudio),
        ("Text-to-Speech", test_speech),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, result))
        except Exception as e:
            print(f"❌ {name} test crashed: {e}")
            results.append((name, False))
    
    print("\n" + "=" * 30)
    print("📊 Test Results:")
    
    all_passed = True
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {name}: {status}")
        if not passed:
            all_passed = False
    
    if all_passed:
        print("\n🎉 All audio tests passed! Audio system is working correctly.")
        return 0
    else:
        print("\n⚠️  Some audio tests failed. Check the configuration.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

chmod +x test_audio.py

# Install Python audio dependencies via system packages
print_status "Installing Python audio dependencies via system packages..."
sudo apt install -y python3-pyaudio python3-speech-recognition python3-pyttsx3 || true

# If system packages aren't available, try pip in user mode with fallback
if ! python3 -c "import pyaudio" 2>/dev/null; then
    print_warning "System packages not available, trying pip with --break-system-packages..."
    pip3 install --user --break-system-packages pyaudio SpeechRecognition pyttsx3 || true
fi

# Start audio services
print_status "Starting audio services..."

# Try to start PulseAudio as a user daemon
print_status "Starting PulseAudio as user daemon..."
pulseaudio --start --daemonize || true

# Alternative: start via systemctl user
systemctl --user start pulseaudio.service 2>/dev/null || true

# Check if PulseAudio is running
if pgrep -x pulseaudio >/dev/null; then
    print_success "PulseAudio is running"
else
    print_warning "PulseAudio failed to start, trying manual start..."
    pulseaudio --daemonize=no --exit-idle-time=-1 &
fi

# Wait a moment for services to start
sleep 3

# Fix permissions
print_status "Fixing audio permissions..."
sudo chown -R $USER:$USER ~/.config/pulse/ || true
sudo chmod 755 ~/.config/pulse/ || true

print_success "Audio configuration completed!"

echo ""
print_status "Testing audio system..."
if python3 test_audio.py; then
    print_success "Audio system is working correctly!"
else
    print_warning "Some audio tests failed. You may need to:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. Check audio hardware connections"
    echo "3. Run: pulseaudio --kill && pulseaudio --start"
fi

echo ""
print_status "To test audio manually:"
echo "• Test speaker: speaker-test -c2 -t wav"
echo "• Test microphone: arecord -d 5 test.wav && aplay test.wav"
echo "• Test TTS: espeak 'Hello world'"
echo "• List devices: pactl list short sinks"
echo ""

print_success "Audio setup complete! Run 'python3 test_audio.py' to test."
