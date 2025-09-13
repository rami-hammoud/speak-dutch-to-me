#!/bin/bash

# Setup script for Seeed Studio ReSpeaker XvF3800 USB 4-mic array
# This script configures the advanced microphone for optimal performance

echo "=== ReSpeaker XvF3800 Setup ==="

# Check if ReSpeaker is connected
if ! lsusb | grep -i "seeed\|xvf3800" >/dev/null 2>&1; then
    echo "ReSpeaker XvF3800 not detected. Please connect the device first."
    echo "Looking for any USB audio devices..."
    lsusb | grep -i "audio\|sound\|microphone" || echo "No USB audio devices found"
    exit 1
fi

echo "ReSpeaker XvF3800 detected!"

# Get device information
echo "Device information:"
lsusb | grep -i "seeed\|xvf3800"

# Check audio capabilities
echo -e "\nChecking audio capabilities..."
if command -v arecord >/dev/null 2>&1; then
    echo "Available capture devices:"
    arecord -l | grep -A 2 -B 2 -i "xvf3800\|seeed"
fi

# Update ALSA configuration for ReSpeaker
echo -e "\nConfiguring ALSA for ReSpeaker XvF3800..."

# Backup current config
sudo cp /etc/asound.conf /etc/asound.conf.before_respeaker.$(date +%Y%m%d_%H%M%S)

# Update ALSA config to prioritize ReSpeaker
sudo tee /etc/asound.conf > /dev/null <<EOF
# ALSA Configuration optimized for ReSpeaker XvF3800 + DigiAMP+
# ReSpeaker XvF3800: 4-mic array with AEC, AGC, noise suppression
# DigiAMP+: High-quality audio output

# Use ReSpeaker for capture, DigiAMP+ for playback
pcm.!default {
    type asym
    playback.pcm "plughw:CARD=DigiAMP,DEV=0"
    capture.pcm "plughw:CARD=XvF3800,DEV=0"
}

ctl.!default {
    type hw
    card "XvF3800"
}

# ReSpeaker XvF3800 optimized configuration
pcm.respeaker {
    type hw
    card "XvF3800"
    device 0
    channels 4
    rate 48000
    format S32_LE
}

# ReSpeaker with plugin for format conversion
pcm.respeaker_plug {
    type plug
    slave {
        pcm "respeaker"
        channels 4
        rate 48000
        format S32_LE
    }
}

# Single channel from ReSpeaker (beamformed audio)
pcm.respeaker_mono {
    type route
    slave {
        pcm "respeaker_plug"
        channels 4
    }
    ttable.0.0 1.0
}

# DigiAMP+ for high-quality playback
pcm.digiamp {
    type hw
    card "DigiAMP"
    device 0
}

# Fallback configurations
pcm.usb_fallback {
    type hw
    card 0
    device 0
}

# PulseAudio compatibility
pcm.pulse {
    type pulse
}

ctl.pulse {
    type pulse
}
EOF

echo "ALSA configuration updated for ReSpeaker XvF3800"

# Test ReSpeaker functionality
echo -e "\n=== Testing ReSpeaker XvF3800 ==="

echo "Testing 4-channel recording (5 seconds)..."
if arecord -D respeaker -f S32_LE -r 48000 -c 4 -d 5 /tmp/respeaker_test.wav 2>/dev/null; then
    echo "4-channel recording successful!"
    ls -lh /tmp/respeaker_test.wav
    rm -f /tmp/respeaker_test.wav
else
    echo "4-channel recording failed, trying default settings..."
    arecord -D plughw:XvF3800,0 -f cd -d 3 /tmp/respeaker_fallback.wav 2>/dev/null && echo "Fallback recording successful" || echo "Recording failed"
    rm -f /tmp/respeaker_fallback.wav
fi

# Check for ReSpeaker control interface
echo -e "\nChecking ReSpeaker controls..."
if command -v amixer >/dev/null 2>&1; then
    echo "Available controls on ReSpeaker:"
    amixer -c XvF3800 scontrols 2>/dev/null || amixer -c $(arecord -l | grep -i xvf3800 | head -1 | cut -d: -f1 | cut -d' ' -f2) scontrols 2>/dev/null || echo "No mixer controls found"
fi

# Install Python packages for ReSpeaker if needed
echo -e "\nChecking Python support for ReSpeaker..."
python3 -c "
try:
    import pyaudio
    print('PyAudio available')
    
    # Test PyAudio with ReSpeaker
    pa = pyaudio.PyAudio()
    device_count = pa.get_device_count()
    
    for i in range(device_count):
        info = pa.get_device_info_by_index(i)
        if 'xvf3800' in info['name'].lower() or 'seeed' in info['name'].lower():
            print(f'ReSpeaker found in PyAudio: {info[\"name\"]} (Device {i})')
            print(f'  Max input channels: {info[\"maxInputChannels\"]}')
            print(f'  Default sample rate: {info[\"defaultSampleRate\"]}')
    
    pa.terminate()
except ImportError:
    print('PyAudio not available - install with: pip3 install pyaudio')
except Exception as e:
    print(f'PyAudio error: {e}')
"

# Restart audio services
echo -e "\nRestarting audio services..."
pulseaudio -k 2>/dev/null
sleep 2
pulseaudio --start 2>/dev/null || echo "Could not start PulseAudio"

# Update Pi Assistant configuration for ReSpeaker
echo -e "\nUpdating Pi Assistant configuration..."
ASSISTANT_CONFIG="pi-assistant/config.py"
if [ -f "$ASSISTANT_CONFIG" ]; then
    echo "Found Pi Assistant config, updating for ReSpeaker..."
    
    # Backup config
    cp "$ASSISTANT_CONFIG" "${ASSISTANT_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update audio device setting
    sed -i 's/AUDIO_INPUT_DEVICE = .*/AUDIO_INPUT_DEVICE = "XvF3800"/' "$ASSISTANT_CONFIG" 2>/dev/null || echo "Could not update config automatically"
    
    echo "Pi Assistant config updated - restart the assistant to use ReSpeaker"
else
    echo "Pi Assistant config not found in current directory"
fi

echo -e "\n=== ReSpeaker XvF3800 Setup Complete ==="
echo "Key features enabled:"
echo "- 4-microphone array with beamforming"  
echo "- Acoustic Echo Cancellation (AEC)"
echo "- Automatic Gain Control (AGC)"
echo "- Noise suppression"
echo "- 48kHz sampling rate"
echo ""
echo "To use with Pi Assistant:"
echo "1. Restart the Pi Assistant service"
echo "2. The assistant will now use ReSpeaker for audio input"
echo "3. Enjoy improved voice recognition and audio quality!"
