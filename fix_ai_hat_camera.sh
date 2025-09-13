#!/bin/bash

# AI HAT+ Camera Fix Script for Raspberry Pi 5
# Fixes libcamera pipeline issues with IMX500 sensor

echo "=== Fixing AI HAT+ Camera (IMX500) ==="

# Check if AI HAT+ is detected
echo "Checking AI HAT+ detection..."
if dmesg | grep -i imx500 >/dev/null 2>&1; then
    echo "✓ IMX500 sensor detected in dmesg"
else
    echo "✗ IMX500 sensor not found in dmesg"
    echo "Check physical connection of AI HAT+"
fi

# Check I2C detection
echo -e "\nChecking I2C devices..."
if i2cdetect -y 1 2>/dev/null | grep -E "(1a|--)" >/dev/null 2>&1; then
    if i2cdetect -y 1 | grep "1a" >/dev/null 2>&1; then
        echo "✓ IMX500 detected on I2C address 0x1a"
    else
        echo "✗ IMX500 not detected on I2C address 0x1a"
    fi
else
    echo "✗ I2C detection failed"
fi

# Check media devices
echo -e "\nChecking media devices..."
if ls /dev/media* >/dev/null 2>&1; then
    echo "✓ Media devices found:"
    ls -la /dev/media*
else
    echo "✗ No media devices found"
fi

# Fix 1: Update libcamera and related packages
echo -e "\n=== Updating Camera Packages ==="
sudo apt update -qq
echo "Updating libcamera packages..."
sudo apt install -y \
    libcamera-apps \
    libcamera-dev \
    libcamera-tools \
    python3-libcamera \
    python3-picamera2 \
    2>/dev/null || echo "Some packages failed to install"

# Fix 2: Create proper IMX500 configuration
echo -e "\n=== Creating IMX500 Configuration ==="

# Create IMX500-specific tuning file if it doesn't exist properly
IMX500_TUNING="/usr/share/libcamera/ipa/rpi/pisp/imx500_ai_hat.json"
if [ ! -f "$IMX500_TUNING" ]; then
    echo "Creating custom IMX500 tuning file..."
    sudo tee "$IMX500_TUNING" > /dev/null <<'EOF'
{
    "version": 2.0,
    "target": "bcm2712",
    "algorithms": [
        {
            "rpi.black_level": {
                "black_level": 4096
            }
        },
        {
            "rpi.dpc": { }
        },
        {
            "rpi.lux": {
                "reference_shutter_speed": 13841,
                "reference_gain": 2.0,
                "reference_aperture": 1.0,
                "reference_lux": 900,
                "reference_Y": 18000
            }
        },
        {
            "rpi.noise": {
                "reference_constant": 0,
                "reference_slope": 2.776,
                "reference_Y": 18000
            }
        },
        {
            "rpi.geq": {
                "offset": 187,
                "slope": 0.01078
            }
        },
        {
            "rpi.sdn": { }
        },
        {
            "rpi.awb": {
                "priors": [
                    { "lux": 0, "prior": [2000, 1.0, 3000, 13.0, 4000, 2.0, 6000, 2.0, 7000, 1.0, 8000, 1.0] },
                    { "lux": 800, "prior": [2000, 2.0, 3000, 13.0, 4000, 4.0, 6000, 6.0, 7000, 1.0, 8000, 1.0] },
                    { "lux": 1500, "prior": [2000, 3.0, 3000, 4.0, 4000, 1.0, 6000, 2.0, 7000, 1.0, 8000, 1.0] }
                ],
                "modes": {
                    "auto": { "lo": 2500, "hi": 8000 },
                    "incandescent": { "lo": 2500, "hi": 3000 },
                    "tungsten": { "lo": 3000, "hi": 3500 },
                    "fluorescent": { "lo": 4000, "hi": 4700 },
                    "indoor": { "lo": 3000, "hi": 5000 },
                    "daylight": { "lo": 5500, "hi": 6500 },
                    "cloudy": { "lo": 7000, "hi": 8500 }
                }
            }
        },
        {
            "rpi.agc": {
                "channels": [
                    {
                        "metering_modes": {
                            "centre-weighted": { "weights": [3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0, 0] },
                            "spot": { "weights": [2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
                            "matrix": { "weights": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] }
                        },
                        "exposure_modes": {
                            "normal": { "shutter": [100, 30000], "gain": [1.0, 8.0] },
                            "short": { "shutter": [100, 10000], "gain": [1.0, 8.0] },
                            "long": { "shutter": [1000, 60000], "gain": [1.0, 8.0] }
                        },
                        "constraint_modes": {
                            "normal": { "bound": "LOWER", "q_lo": 0.98, "q_hi": 1.0, "y_target": [0, 0.4, 1000, 0.4, 10000, 0.3] }
                        }
                    }
                ]
            }
        },
        {
            "rpi.alsc": {
                "omega": 1.3,
                "n_iter": 100,
                "luminance_strength": 0.7
            }
        },
        {
            "rpi.contrast": {
                "ce_enable": 1,
                "gamma_curve": [0, 0, 1024, 5040, 2048, 9338, 3072, 12356, 4096, 15312, 5120, 18051, 6144, 20790, 7168, 23193, 8192, 25744, 9216, 27942, 10240, 30035, 11264, 32005, 12288, 33975, 13312, 35815, 14336, 37578, 15360, 39168, 16384, 40642, 18432, 43379, 20480, 45749, 22528, 47753, 24576, 49621, 26624, 51253, 28672, 52698, 30720, 53968, 32768, 65535]
            }
        },
        {
            "rpi.ccm": { }
        },
        {
            "rpi.sharpen": { }
        }
    ]
}
EOF
    echo "✓ Custom IMX500 tuning file created"
else
    echo "✓ IMX500 tuning file already exists"
fi

# Fix 3: Update boot configuration for AI HAT+
echo -e "\n=== Updating Boot Configuration ==="

if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "✗ Boot config file not found"
    CONFIG_FILE=""
fi

if [ -n "$CONFIG_FILE" ]; then
    echo "Updating $CONFIG_FILE..."
    
    # Backup config
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove conflicting camera settings
    sudo sed -i '/^camera_auto_detect=/d' "$CONFIG_FILE"
    sudo sed -i '/^dtoverlay=camera/d' "$CONFIG_FILE"
    sudo sed -i '/^dtoverlay=imx500/d' "$CONFIG_FILE"
    
    # Add AI HAT+ specific settings
    if ! grep -q "dtoverlay=imx500,media-controller=0" "$CONFIG_FILE"; then
        echo "" | sudo tee -a "$CONFIG_FILE"
        echo "# AI HAT+ Camera Configuration" | sudo tee -a "$CONFIG_FILE"
        echo "dtoverlay=imx500,media-controller=0" | sudo tee -a "$CONFIG_FILE"
        echo "camera_auto_detect=0" | sudo tee -a "$CONFIG_FILE"
        echo "✓ AI HAT+ configuration added to boot config"
    else
        echo "✓ AI HAT+ configuration already present"
    fi
fi

# Fix 4: Set environment variables for libcamera
echo -e "\n=== Setting libcamera environment ==="

# Create environment file for Pi Assistant
sudo tee /etc/environment.d/99-libcamera.conf > /dev/null <<EOF
LIBCAMERA_LOG_LEVELS=*:WARN
LIBCAMERA_RPI_TUNING_FILE=/usr/share/libcamera/ipa/rpi/pisp/imx500_ai_hat.json
EOF

echo "✓ libcamera environment configured"

# Fix 5: Test AI HAT+ camera
echo -e "\n=== Testing AI HAT+ Camera ==="

echo "Testing libcamera detection..."
timeout 10 libcamera-hello --list-cameras 2>/dev/null && echo "✓ Camera detection successful" || echo "✗ Camera detection failed"

echo -e "\nTesting image capture..."
if timeout 15 libcamera-still -o /tmp/ai_hat_test.jpg --timeout 2000 --nopreview 2>/dev/null; then
    if [ -f /tmp/ai_hat_test.jpg ]; then
        echo "✓ AI HAT+ image capture successful"
        ls -lh /tmp/ai_hat_test.jpg
        rm -f /tmp/ai_hat_test.jpg
    else
        echo "✗ Image file not created"
    fi
else
    echo "✗ AI HAT+ image capture failed"
fi

# Fix 6: Create AI HAT+ specific Python test
echo -e "\n=== Creating AI HAT+ Python Test ==="

cat > /tmp/test_ai_hat_camera.py << 'EOF'
#!/usr/bin/env python3
import os
import time

# Set environment for IMX500
os.environ['LIBCAMERA_LOG_LEVELS'] = '*:WARN'
os.environ['LIBCAMERA_RPI_TUNING_FILE'] = '/usr/share/libcamera/ipa/rpi/pisp/imx500_ai_hat.json'

try:
    from picamera2 import Picamera2
    print("✓ Picamera2 import successful")
    
    # Create camera with specific configuration for IMX500
    picam2 = Picamera2()
    print("✓ Camera instance created")
    
    # Get camera info
    cameras = picam2.global_camera_info()
    print(f"Available cameras: {len(cameras)}")
    for i, cam in enumerate(cameras):
        print(f"  Camera {i}: {cam}")
    
    # Configure for IMX500 with safe settings
    config = picam2.create_still_configuration(
        main={"size": (1280, 720), "format": "RGB888"},
        buffer_count=2
    )
    print("✓ Configuration created")
    
    picam2.configure(config)
    print("✓ Camera configured")
    
    picam2.start()
    print("✓ Camera started")
    
    # Wait for camera to stabilize
    time.sleep(3)
    
    # Capture image
    picam2.capture_file("/tmp/ai_hat_python_test.jpg")
    print("✓ Image captured")
    
    picam2.stop()
    picam2.close()
    print("✓ Camera closed successfully")
    
    # Check file
    if os.path.exists("/tmp/ai_hat_python_test.jpg"):
        size = os.path.getsize("/tmp/ai_hat_python_test.jpg")
        print(f"✓ Image file created: {size} bytes")
        os.remove("/tmp/ai_hat_python_test.jpg")
    
    print("AI HAT+ Python test: SUCCESS")
    
except Exception as e:
    print(f"AI HAT+ Python test: FAILED - {e}")
    import traceback
    traceback.print_exc()
EOF

echo "Running AI HAT+ Python test..."
python3 /tmp/test_ai_hat_camera.py
rm -f /tmp/test_ai_hat_camera.py

echo -e "\n=== AI HAT+ Camera Fix Complete ==="
echo "Summary:"
echo "- Updated libcamera packages"
echo "- Created IMX500-specific tuning file"
echo "- Updated boot configuration"
echo "- Set proper environment variables"
echo "- Tested camera functionality"
echo ""
echo "If camera still doesn't work:"
echo "1. Reboot the system: sudo reboot"
echo "2. Check AI HAT+ physical connection"
echo "3. Verify camera ribbon cable is properly seated"
echo "4. Check for firmware updates: sudo rpi-update"
echo ""
echo "After reboot, test with: libcamera-hello --timeout 5000"
