#!/bin/bash

# Comprehensive Camera Fix Script for Pi Assistant
# This script diagnoses and fixes camera issues on Raspberry Pi 5

echo "=== Pi Assistant Camera Fix ==="

# Check if we're on the Pi (not Mac)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "This script should be run on the Raspberry Pi, not on Mac"
    exit 1
fi

# Check system info
echo "System Information:"
uname -a
cat /proc/cpuinfo | grep "Model" || echo "Could not determine Pi model"

# Check camera hardware detection
echo -e "\n=== Hardware Detection ==="

echo "Checking libcamera devices:"
libcamera-hello --list-cameras 2>/dev/null || echo "No libcamera devices found"

echo -e "\nChecking USB video devices:"
ls -la /dev/video* 2>/dev/null || echo "No USB video devices found"

echo -e "\nChecking I2C devices (for Pi Camera):"
i2cdetect -y 1 2>/dev/null || echo "I2C detection failed"

# Check camera modules and drivers
echo -e "\n=== Driver and Module Status ==="

echo "Loaded camera modules:"
lsmod | grep -E "video|camera|v4l|uvc" || echo "No camera modules loaded"

echo -e "\nVideo4Linux devices:"
if command -v v4l2-ctl >/dev/null 2>&1; then
    for device in /dev/video*; do
        if [ -e "$device" ]; then
            echo "Device: $device"
            v4l2-ctl --device="$device" --list-formats-ext 2>/dev/null | head -5
        fi
    done 2>/dev/null
else
    echo "v4l2-ctl not available (install with: sudo apt install v4l-utils)"
fi

# Test camera functionality
echo -e "\n=== Testing Camera Functionality ==="

echo "Testing libcamera (Pi Camera):"
timeout 5 libcamera-hello --nopreview 2>/dev/null && echo "Pi Camera test: SUCCESS" || echo "Pi Camera test: FAILED"

echo -e "\nTesting libcamera capture:"
libcamera-still -o /tmp/test_pi_cam.jpg --nopreview --immediate 2>/dev/null && echo "Pi Camera capture: SUCCESS" || echo "Pi Camera capture: FAILED"
[ -f /tmp/test_pi_cam.jpg ] && rm /tmp/test_pi_cam.jpg

# Test USB cameras if available
if ls /dev/video* >/dev/null 2>&1; then
    echo -e "\nTesting USB cameras with fswebcam:"
    if command -v fswebcam >/dev/null 2>&1; then
        fswebcam -d /dev/video0 --no-banner -r 640x480 /tmp/test_usb_cam.jpg 2>/dev/null && echo "USB Camera test: SUCCESS" || echo "USB Camera test: FAILED"
        [ -f /tmp/test_usb_cam.jpg ] && rm /tmp/test_usb_cam.jpg
    else
        echo "fswebcam not available (install with: sudo apt install fswebcam)"
    fi
fi

# Check Python camera libraries
echo -e "\n=== Python Library Status ==="

echo "Checking OpenCV installation:"
python3 -c "
try:
    import cv2
    print(f'OpenCV version: {cv2.__version__}')
    
    # Test camera access
    cap = cv2.VideoCapture(0)
    if cap.isOpened():
        print('OpenCV can access camera device 0')
        ret, frame = cap.read()
        if ret:
            print(f'Successfully captured frame: {frame.shape}')
        else:
            print('Could not capture frame')
        cap.release()
    else:
        print('OpenCV cannot access camera device 0')
except ImportError:
    print('OpenCV not installed')
except Exception as e:
    print(f'OpenCV error: {e}')
"

echo -e "\nChecking Picamera2:"
python3 -c "
try:
    from picamera2 import Picamera2
    import libcamera
    print('Picamera2 available')
    
    # Test Picamera2 initialization
    picam2 = Picamera2()
    cameras = Picamera2.global_camera_info()
    print(f'Detected cameras: {len(cameras)}')
    for i, cam in enumerate(cameras):
        print(f'  Camera {i}: {cam}')
    
    if cameras:
        # Try to configure and start
        try:
            picam2.configure(picam2.create_still_configuration())
            print('Picamera2 configuration successful')
        except Exception as e:
            print(f'Picamera2 configuration error: {e}')
    
except ImportError as e:
    print(f'Picamera2 not available: {e}')
except Exception as e:
    print(f'Picamera2 error: {e}')
"

# Check Pi Assistant camera manager
echo -e "\n=== Pi Assistant Camera Manager Test ==="

if [ -f "pi-assistant/ui/camera_manager.py" ]; then
    cd pi-assistant
    python3 -c "
import asyncio
import sys
sys.path.append('.')

async def test_camera_manager():
    try:
        from ui.camera_manager import CameraManager
        
        camera_manager = CameraManager()
        print('CameraManager instantiated')
        
        await camera_manager.initialize()
        print(f'Camera available: {camera_manager.camera_available}')
        print(f'Using Pi Camera: {camera_manager.picamera is not None}')
        print(f'Using USB Camera: {camera_manager.camera is not None and camera_manager.picamera is None}')
        
        if camera_manager.camera_available:
            frame = await camera_manager.get_frame()
            if frame:
                print('Successfully captured frame via camera manager')
                print(f'Frame data length: {len(frame)}')
            else:
                print('Camera manager returned no frame')
        
        await camera_manager.cleanup()
        
    except Exception as e:
        print(f'Camera manager error: {e}')
        import traceback
        traceback.print_exc()

asyncio.run(test_camera_manager())
"
    cd ..
else
    echo "Pi Assistant camera manager not found in current directory"
fi

# Fix common issues
echo -e "\n=== Attempting Common Fixes ==="

# Fix camera permissions
echo "Setting camera permissions:"
sudo usermod -a -G video $USER 2>/dev/null || echo "Could not add user to video group"

# Enable camera in raspi-config if needed
echo "Checking camera enable status:"
if [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
elif [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE=""
fi

if [ -n "$CONFIG_FILE" ]; then
    if ! grep -q "^camera_auto_detect=1" "$CONFIG_FILE"; then
        echo "Enabling camera auto-detect..."
        echo "camera_auto_detect=1" | sudo tee -a "$CONFIG_FILE"
    fi
    
    if grep -q "^start_x=0" "$CONFIG_FILE"; then
        echo "Enabling camera support (start_x=1)..."
        sudo sed -i 's/^start_x=0/start_x=1/' "$CONFIG_FILE"
    fi
fi

# Install missing packages
echo -e "\nInstalling/updating camera packages:"
sudo apt update -qq
sudo apt install -y v4l-utils fswebcam python3-opencv 2>/dev/null || echo "Some packages failed to install"

# Update libcamera if available
echo "Updating libcamera:"
sudo apt install -y libcamera-apps libcamera-dev 2>/dev/null || echo "libcamera update failed"

echo -e "\n=== Camera Fix Complete ==="
echo "Summary of findings:"
echo "- Check the hardware detection section above"
echo "- If Pi Camera failed, check physical connection and enable camera in raspi-config"
echo "- If USB Camera failed, check USB connection and try different ports"
echo "- If Python libraries failed, the Pi Assistant may not work properly"
echo ""
echo "To apply some fixes, you may need to reboot: sudo reboot"
echo ""
echo "After reboot, test the Pi Assistant camera by running:"
echo "  cd pi-assistant && python3 main.py"
echo "Then open the web interface and check the camera view"
