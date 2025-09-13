#!/bin/bash

# Workaround for Pi Camera libcamera crash
# Forces USB camera usage to avoid IMX500 libcamera issues

echo "=== Pi Camera Crash Workaround ==="

echo "This script will configure the Pi Assistant to use USB camera instead of Pi Camera"
echo "This avoids the libcamera crash with IMX500 on Pi 5"

# Backup current config
if [ -f "pi-assistant/config.py" ]; then
    cp "pi-assistant/config.py" "pi-assistant/config.py.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Config backed up"
fi

# Update config to force USB camera
cat > /tmp/camera_config_patch.py << 'EOF'
import re

# Read current config
with open('pi-assistant/config.py', 'r') as f:
    content = f.read()

# Add USB camera preference if not already present
if 'FORCE_USB_CAMERA' not in content:
    # Add the setting after camera settings
    camera_section = """
# Camera workaround for libcamera crashes
FORCE_USB_CAMERA = True  # Set to True to avoid Pi Camera libcamera issues
"""
    
    # Find a good place to insert (after camera settings)
    if 'CAMERA_ENABLED' in content:
        content = re.sub(r'(CAMERA_ENABLED\s*=.*?\n)', r'\1' + camera_section, content)
    else:
        content += camera_section

# Write updated config
with open('pi-assistant/config.py', 'w') as f:
    f.write(content)

print("Config updated with USB camera preference")
EOF

python3 /tmp/camera_config_patch.py
rm /tmp/camera_config_patch.py

# Update camera manager to respect the force USB setting
if [ -f "pi-assistant/ui/camera_manager.py" ]; then
    echo "Updating camera manager for USB camera preference..."
    
    # Create a patch for the camera manager
    cat > /tmp/camera_manager_patch.py << 'EOF'
import re

# Read camera manager
with open('pi-assistant/ui/camera_manager.py', 'r') as f:
    content = f.read()

# Add import for config at the top if not present
if 'from config import config' not in content:
    print("Config import already present")
else:
    # Find the initialization method and add USB camera preference
    if 'FORCE_USB_CAMERA' not in content:
        # Add check for force USB camera setting
        init_pattern = r'(# Try to initialize Pi Camera first\s*\n\s*if self\._pi_camera_available:)'
        replacement = r'# Try to initialize Pi Camera first (unless forced to use USB)\n        if self._pi_camera_available and not getattr(config, "FORCE_USB_CAMERA", False):'
        
        content = re.sub(init_pattern, replacement, content, flags=re.MULTILINE)
        
        if init_pattern in content:
            print("Camera manager updated for USB preference")
        else:
            print("Could not find initialization section to patch")

# Write updated camera manager
with open('pi-assistant/ui/camera_manager.py', 'w') as f:
    f.write(content)
EOF

    python3 /tmp/camera_manager_patch.py
    rm /tmp/camera_manager_patch.py
fi

echo -e "\n=== Workaround Applied ==="
echo "Changes made:"
echo "1. Added FORCE_USB_CAMERA = True to config.py" 
echo "2. Updated camera manager to prefer USB camera"
echo ""
echo "This should prevent the libcamera crash by avoiding Pi Camera initialization"
echo ""
echo "To test:"
echo "1. Connect a USB webcam"
echo "2. Run: python3 test_camera_safe.py"
echo "3. Start Pi Assistant: cd pi-assistant && python3 main.py"
echo ""
echo "To revert: restore from config.py.backup.* files"
