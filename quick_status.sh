#!/bin/bash

# Quick AI HAT+ Status Check
echo "🚀 Quick AI HAT+ Status Check"
echo "=============================="

echo ""
echo "📦 Installed Packages:"
dpkg -l | grep -i hailo || echo "   No Hailo packages found"

echo ""
echo "🔧 HailoRT CLI:"
if command -v hailortcli >/dev/null 2>&1; then
    echo "   ✅ HailoRT CLI available"
    echo "   Version: $(hailortcli --version 2>/dev/null || echo 'Unknown')"
    echo "   Device scan:"
    hailortcli scan 2>/dev/null || echo "   ❌ No devices found or scan failed"
else
    echo "   ❌ HailoRT CLI not found"
fi

echo ""
echo "🔍 Hardware Detection:"
if lspci 2>/dev/null | grep -i hailo; then
    echo "   ✅ Hailo device found in PCI"
else
    echo "   ❌ No Hailo device in PCI"
fi

echo ""
echo "📋 Recent Kernel Messages:"
dmesg | grep -i hailo | tail -3 || echo "   No recent Hailo messages"

echo ""
echo "🐍 Python Modules:"
python3 -c "
modules = ['hailo_platform_api', 'hailort', 'hailo', 'cv2', 'numpy']
for module in modules:
    try:
        __import__(module)
        print(f'   ✅ {module}')
    except ImportError:
        print(f'   ❌ {module}')
"

echo ""
echo "📁 Current Directory Files:"
ls -la *.deb 2>/dev/null | head -3 || echo "   No .deb files found"

echo ""
echo "🎯 Run full check: python3 final_check_ai_hat.py"
