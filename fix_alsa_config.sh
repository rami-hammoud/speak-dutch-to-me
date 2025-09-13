#!/bin/bash

# Fix ALSA Configuration Script for Raspberry Pi
# This script fixes corrupted /etc/asound.conf and sets up proper audio

echo "=== Fixing ALSA Configuration ==="

# Backup existing config if it exists
if [ -f /etc/asound.conf ]; then
    echo "Backing up existing asound.conf..."
    sudo cp /etc/asound.conf /etc/asound.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Remove corrupted asound.conf
echo "Removing corrupted asound.conf..."
sudo rm -f /etc/asound.conf

# Create new clean asound.conf optimized for your hardware
echo "Creating new asound.conf..."
sudo tee /etc/asound.conf > /dev/null <<EOF
# ALSA Configuration for Raspberry Pi with USB Audio and DigiAMP+
# Optimized for current hardware + future Seeed ReSpeaker XvF3800 USB 4-mic array
# Supports: USB PnP Sound Device, ReSpeaker XvF3800, DigiAMP+ (playback)

# Auto-detect and use best available microphone (prioritizes ReSpeaker if available)
pcm.!default {
    type asym
    playback.pcm "plughw:CARD=DigiAMP,DEV=0"
    capture.pcm "plughw:CARD=Device,DEV=0"
}

ctl.!default {
    type hw
    card 1
}

# ReSpeaker XvF3800 USB 4-mic array (future upgrade)
pcm.respeaker {
    type hw
    card "XvF3800" 
    device 0
    channels 4
    rate 48000
}

# Current USB Audio for capture (microphone)
pcm.usb_mic {
    type hw
    card 0
    device 0
}

# DigiAMP+ for playback (speakers)
pcm.digiamp {
    type hw  
    card 1
    device 0
}

# Smart microphone selection - tries ReSpeaker first, falls back to USB mic
pcm.smart_mic {
    type plug
    slave.pcm {
        @func refer
        name { @func concat strings [ "hw:CARD=" { @func card_name card "XvF3800" } ",DEV=0" ] }
        default "plughw:0,0"
    }
}

# PulseAudio compatibility
pcm.pulse {
    type pulse
}

ctl.pulse {
    type pulse
}

# Fallback to hardware if PulseAudio is not available
pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 44100
    }
    bindings {
        0 0
        1 1
    }
}

pcm.dsnooper {
    type dsnoop
    ipc_key 2048
    slave {
        pcm "hw:0,0"
        channels 2
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 44100
    }
    bindings {
        0 0
        1 1
    }
}

pcm.duplex {
    type asym
    playback.pcm "dmixer"
    capture.pcm "dsnooper"
}
EOF

echo "Created new asound.conf"

# Check audio devices
echo "=== Audio Device Information ==="
echo "Available playback devices:"
aplay -l 2>/dev/null || echo "No playback devices found"

echo -e "\nAvailable capture devices:"
arecord -l 2>/dev/null || echo "No capture devices found"

echo -e "\nALSA cards:"
cat /proc/asound/cards 2>/dev/null || echo "No sound cards found"

# Set proper permissions
echo "Setting proper permissions..."
sudo chmod 644 /etc/asound.conf

# Restart audio services
echo "Restarting audio services..."
sudo systemctl restart alsa-state 2>/dev/null || echo "alsa-state service not available"
sudo systemctl restart pulseaudio 2>/dev/null || echo "pulseaudio system service not available"

# Kill and restart user pulseaudio
echo "Restarting user PulseAudio..."
pulseaudio -k 2>/dev/null || echo "PulseAudio not running"
sleep 2
pulseaudio --start 2>/dev/null || echo "Could not start PulseAudio"

# Test audio
echo "=== Testing Audio ==="
echo "Testing speaker (you should hear a tone):"
if command -v speaker-test >/dev/null 2>&1; then
    timeout 5 speaker-test -t sine -f 1000 -l 1 2>/dev/null || echo "Speaker test failed"
else
    echo "speaker-test not available"
fi

echo "Testing microphone (speak for 3 seconds):"
if command -v arecord >/dev/null 2>&1; then
    timeout 3 arecord -f cd /tmp/test_audio.wav 2>/dev/null && echo "Microphone test completed" || echo "Microphone test failed"
    rm -f /tmp/test_audio.wav
else
    echo "arecord not available"
fi

echo "=== ALSA Configuration Fix Complete ==="
echo "If you still have audio issues, try:"
echo "1. sudo raspi-config -> Advanced Options -> Audio -> Force 3.5mm jack"
echo "2. Reboot the system"
echo "3. Check hardware connections"
