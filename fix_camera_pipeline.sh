#!/bin/bash

# Fix Camera Pipeline for Raspberry Pi 5 with AI HAT+
# This script addresses libcamera pipeline configuration issues and camera initialization

echo "=== Fixing Camera Pipeline Configuration ==="

# Check if we're on a Pi 5
if grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
    echo "Detected Raspberry Pi 5"
else
    echo "Warning: This script is designed for Raspberry Pi 5"
fi

# Check current libcamera version
echo "Current libcamera version:"
dpkg -l | grep libcamera || echo "libcamera packages not found"

# Check for audio devices (current and future ReSpeaker)
echo -e "\nChecking audio devices for future ReSpeaker XvF3800..."
if lsusb | grep -i "seeed\|xvf3800" >/dev/null 2>&1; then
    echo "ReSpeaker XvF3800 detected!"
elif lsusb | grep -i "c-media" >/dev/null 2>&1; then
    echo "Current USB audio device detected"
else
    echo "No advanced audio devices detected yet"
fi

# Backup existing pipeline config if it exists
PIPELINE_CONFIG="/usr/share/libcamera/pipeline/rpi/vc4/rpi_apps.yaml"
if [ -f "$PIPELINE_CONFIG" ]; then
    echo "Backing up existing pipeline config..."
    sudo cp "$PIPELINE_CONFIG" "${PIPELINE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Check for PiSP variant configuration
PISP_CONFIG="/usr/share/libcamera/pipeline/rpi/pisp"
if [ -d "$PISP_CONFIG" ]; then
    echo "PiSP configuration directory found: $PISP_CONFIG"
    ls -la "$PISP_CONFIG"
else
    echo "PiSP configuration directory not found"
fi

# Create a compatible pipeline configuration for Pi 5
echo "Creating Pi 5 compatible pipeline configuration..."
sudo mkdir -p "$(dirname "$PIPELINE_CONFIG")"

sudo tee "$PIPELINE_CONFIG" > /dev/null <<EOF
# Pipeline configuration for Raspberry Pi 5 with AI HAT+
# Compatible with both PiSP and legacy configurations

%YAML 1.1
---
"target": "pisp"

"pipelines":
    rpi/pisp:
        - "pipeline_handler": "PipelineHandlerRPi"
          "dma_heaps": ["/dev/dma_heap/linux,cma"]
          "min_total_unicam_buffers": 4
          "disable_startup_frame_drops": false
          "enable_hdr": false

# Fallback for BCM2835 compatibility  
"bcm2835":
    rpi/vc4:
        - "pipeline_handler": "PipelineHandlerRPi" 
          "dma_heaps": ["/dev/dma_heap/linux,cma"]
          "min_total_unicam_buffers": 4
          "disable_startup_frame_drops": false
EOF

echo "Pipeline configuration updated"

# Update camera firmware and overlays
echo "Checking camera firmware..."

# Enable camera in config.txt if not already enabled
CONFIG_TXT="/boot/firmware/config.txt"
if [ -f "$CONFIG_TXT" ]; then
    echo "Checking camera configuration in $CONFIG_TXT..."
    
    # Check if camera is enabled
    if ! grep -q "^camera_auto_detect=1" "$CONFIG_TXT"; then
        echo "Enabling camera auto-detect..."
        echo "camera_auto_detect=1" | sudo tee -a "$CONFIG_TXT"
    fi
    
    # Ensure dtparam=camera=on
    if ! grep -q "^dtparam=camera=on" "$CONFIG_TXT"; then
        echo "Enabling camera parameter..."
        echo "dtparam=camera=on" | sudo tee -a "$CONFIG_TXT"
    fi
    
    # Check for AI HAT+ specific configuration
    if ! grep -q "dtoverlay.*imx500" "$CONFIG_TXT"; then
        echo "Adding AI HAT+ camera overlay..."
        echo "dtoverlay=imx500,media-controller=0" | sudo tee -a "$CONFIG_TXT"
    fi
else
    echo "Warning: Could not find $CONFIG_TXT"
fi

# Restart camera services
echo "Restarting camera-related services..."
sudo systemctl restart systemd-modules-load 2>/dev/null || echo "systemd-modules-load not available"

# Check camera detection
echo "=== Camera Detection Test ==="
echo "Available cameras:"
libcamera-hello --list-cameras 2>/dev/null || echo "libcamera-hello not available or no cameras detected"

echo "V4L2 devices:"
ls -la /dev/video* 2>/dev/null || echo "No video devices found"

echo "Media devices:"  
ls -la /dev/media* 2>/dev/null || echo "No media devices found"

# Test camera functionality
echo "=== Testing Camera ==="

echo "Testing with libcamera-hello (if available):"
if command -v libcamera-hello >/dev/null 2>&1; then
    timeout 5 libcamera-hello --timeout 1000 2>/dev/null && echo "libcamera-hello test passed" || echo "libcamera-hello test failed"
else
    echo "libcamera-hello not available"
fi

echo -e "\nTesting with Python picamera2:"
python3 -c "
import sys
try:
    from picamera2 import Picamera2
    print('Picamera2 import successful')
    
    try:
        picam2 = Picamera2()
        print('Picamera2 instance created')
        
        config = picam2.create_preview_configuration(main={'size': (640, 480), 'format': 'RGB888'})
        picam2.configure(config)
        print('Camera configured successfully')
        
        picam2.start()
        print('Camera started successfully') 
        
        picam2.stop()
        print('Camera stopped successfully')
        
        picam2.close()
        print('Camera closed successfully')
        
        print('Pi Camera test: PASSED')
        
    except Exception as e:
        print(f'Picamera2 error: {e}')
        print('Pi Camera test: FAILED')
        
except ImportError as e:
    print(f'Picamera2 not available: {e}')
"

echo -e "\nTesting with OpenCV:"
python3 -c "
import sys
try:
    import cv2
    print('OpenCV import successful')
    
    cap = cv2.VideoCapture(0)
    if cap.isOpened():
        print('USB camera opened successfully')
        ret, frame = cap.read()
        if ret:
            print(f'Frame captured successfully: {frame.shape}')
            print('USB Camera test: PASSED')
        else:
            print('Failed to capture frame')
            print('USB Camera test: FAILED')
        cap.release()
    else:
        print('Failed to open USB camera')
        print('USB Camera test: FAILED')
        
except ImportError as e:
    print(f'OpenCV not available: {e}')
except Exception as e:
    print(f'OpenCV error: {e}')
"

if command -v libcamera-still >/dev/null 2>&1; then
    echo -e "\nTesting camera capture (saving test image)..."
    timeout 10 libcamera-still --output /tmp/test_camera.jpg --timeout 2000 2>/dev/null && echo "Camera capture successful" || echo "Camera capture failed"
    if [ -f /tmp/test_camera.jpg ]; then
        echo "Test image saved: /tmp/test_camera.jpg ($(stat -f%z /tmp/test_camera.jpg 2>/dev/null || stat -c%s /tmp/test_camera.jpg) bytes)"
        rm -f /tmp/test_camera.jpg
    fi
else
    echo "libcamera-still not available"
fi

# Check camera permissions and processes
echo "=== Camera Permissions and Processes ==="
groups $USER | grep -E "(video|camera)" && echo "User has camera permissions" || echo "User may need camera permissions"

echo -e "\nChecking for camera processes:"
ps aux | grep -E "(libcamera|picamera|camera)" | grep -v grep || echo "No camera processes found"

echo -e "\nCamera kernel modules:"
lsmod | grep -E "(bcm2835|imx500|v4l2)" || echo "No camera modules loaded"

# Check for AI HAT+ specific functionality
echo "=== AI HAT+ Detection ==="
if [ -d "/sys/class/gpio" ]; then
    echo "GPIO interface available"
    # Check for AI HAT+ specific GPIO or I2C devices
    if [ -d "/sys/bus/i2c/devices/1-001a" ]; then
        echo "IMX500 sensor detected on I2C"
    else
        echo "IMX500 sensor not detected on expected I2C address"
    fi
fi

echo -e "\nCamera status from vcgencmd:"
vcgencmd get_camera 2>/dev/null || echo "vcgencmd not available"

echo -e "\nDmesg camera-related messages (last 20):"
dmesg | grep -iE "(camera|imx500|picamera|v4l2)" | tail -20 || echo "No camera messages in dmesg"

echo "=== Camera Pipeline Fix Complete ==="
echo "If camera issues persist:"
echo "1. Reboot the system: sudo reboot"
echo "2. Update firmware: sudo rpi-update"
echo "3. Check hardware connections"
echo "4. Verify AI HAT+ is properly seated"
echo ""
echo "To test after reboot:"
echo "libcamera-hello --list-cameras"
echo "libcamera-still --output test.jpg"
