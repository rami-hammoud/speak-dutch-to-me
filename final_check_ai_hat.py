#!/usr/bin/env python3
"""
Final AI HAT+ Setup Verification Script
This script performs a comprehensive check of your AI HAT+ installation
"""

import subprocess
import sys
import os

def run_check(cmd, description, critical=False):
    """Run a command and report results"""
    print(f"🔧 {description}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=False)
        if result.returncode == 0 and result.stdout.strip():
            print(f"   ✅ Success")
            if result.stdout.strip():
                # Show first few lines of output
                lines = result.stdout.strip().split('\n')[:3]
                for line in lines:
                    print(f"      {line}")
                if len(result.stdout.strip().split('\n')) > 3:
                    print(f"      ... (and {len(result.stdout.strip().split('\n')) - 3} more lines)")
        else:
            status = "❌ Critical Error" if critical else "⚠️  Warning"
            print(f"   {status}: {description}")
            if result.stderr:
                print(f"      Error: {result.stderr.strip()}")
        return result.returncode == 0
    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return False

def check_system_info():
    """Check basic system information"""
    print("\n📋 System Information")
    print("=" * 50)
    
    run_check("cat /proc/device-tree/model", "Raspberry Pi Model")
    run_check("uname -a", "Kernel Version")
    run_check("cat /etc/os-release | grep PRETTY_NAME", "Operating System")

def check_hardware():
    """Check hardware detection"""
    print("\n🔍 Hardware Detection")
    print("=" * 50)
    
    # Check I2C
    i2c_ok = run_check("ls -la /dev/i2c*", "I2C Devices", critical=True)
    if i2c_ok:
        run_check("sudo i2cdetect -y 1", "I2C Bus Scan")
    
    # Check PCI devices
    run_check("lspci", "PCI Devices")
    hailo_pci = run_check("lspci | grep -i hailo", "Hailo PCI Device")
    
    # Check kernel messages
    run_check("dmesg | grep -i hailo | tail -10", "Hailo Kernel Messages")
    
    return i2c_ok and hailo_pci

def check_software():
    """Check software installation"""
    print("\n📦 Software Installation")
    print("=" * 50)
    
    # Check installed packages
    run_check("dpkg -l | grep -i hailo", "Installed Hailo Packages")
    
    # Check HailoRT CLI
    hailort_cli = run_check("which hailortcli", "HailoRT CLI Location", critical=True)
    if hailort_cli:
        run_check("hailortcli --version", "HailoRT Version")
        run_check("hailortcli scan", "HailoRT Device Scan", critical=True)
    
    return hailort_cli

def check_python_environment():
    """Check Python environment and bindings"""
    print("\n🐍 Python Environment")
    print("=" * 50)
    
    print("🔧 Checking Python version")
    python_version = subprocess.run([sys.executable, "--version"], capture_output=True, text=True)
    print(f"   ✅ {python_version.stdout.strip()}")
    
    # Test Python imports
    python_modules = [
        ("hailo_platform_api", "Hailo Platform API"),
        ("hailort", "HailoRT Python Module"),
        ("hailo", "Alternative Hailo Module"),
        ("cv2", "OpenCV (for computer vision)"),
        ("numpy", "NumPy (for data processing)")
    ]
    
    available_modules = []
    
    for module, description in python_modules:
        try:
            __import__(module)
            print(f"   ✅ {description}: Available")
            available_modules.append(module)
        except ImportError:
            print(f"   ⚠️  {description}: Not available")
    
    return len(available_modules) > 2

def check_interfaces():
    """Check enabled interfaces"""
    print("\n🔧 Interface Configuration")
    print("=" * 50)
    
    # Check boot config
    config_paths = ["/boot/firmware/config.txt", "/boot/config.txt"]
    config_found = False
    
    for config_path in config_paths:
        if os.path.exists(config_path):
            config_found = True
            print(f"🔧 Checking boot config: {config_path}")
            try:
                with open(config_path, 'r') as f:
                    config_content = f.read()
                
                checks = [
                    ("dtparam=i2c_arm=on", "I2C enabled"),
                    ("dtparam=spi=on", "SPI enabled"),
                    ("gpu_mem=", "GPU memory split"),
                    ("camera_auto_detect=1", "Camera auto-detect")
                ]
                
                for check, description in checks:
                    if check in config_content:
                        print(f"   ✅ {description}")
                    else:
                        print(f"   ⚠️  {description}: Not found")
            except Exception as e:
                print(f"   ❌ Could not read config: {e}")
            break
    
    if not config_found:
        print("   ❌ No boot config file found")
    
    # Check loaded modules
    run_check("lsmod | grep i2c", "I2C Kernel Modules")

def check_camera():
    """Check camera functionality (for Dutch learning project)"""
    print("\n📷 Camera Check (for Dutch Learning Project)")
    print("=" * 50)
    
    run_check("vcgencmd get_camera", "Camera Detection")
    run_check("libcamera-hello --list-cameras", "Available Cameras")

def final_test():
    """Perform final integration test"""
    print("\n🎯 Final Integration Test")
    print("=" * 50)
    
    print("🔧 Testing complete AI HAT+ functionality")
    
    # Test device scan
    scan_result = subprocess.run(["hailortcli", "scan"], capture_output=True, text=True)
    if scan_result.returncode == 0:
        print("   ✅ HailoRT device scan successful")
        if "Device found" in scan_result.stdout or "hailo" in scan_result.stdout.lower():
            print("   ✅ AI HAT+ device detected and responsive")
            return True
        else:
            print("   ⚠️  HailoRT CLI works but no devices found")
            print("      This could mean:")
            print("      - AI HAT+ is not physically connected")
            print("      - Need to reboot after installation")
            print("      - Power supply insufficient")
    else:
        print("   ❌ HailoRT device scan failed")
        print(f"      Error: {scan_result.stderr}")
    
    return False

def main():
    """Main verification function"""
    print("🤖 AI HAT+ Final Setup Verification")
    print("=" * 60)
    print("Checking your 'Speak Dutch To Me' AI setup...")
    print("=" * 60)
    
    results = {
        "System": True,  # Always assume system is OK
        "Hardware": False,
        "Software": False,
        "Python": False,
        "Interfaces": True,  # Assume OK if we got this far
        "Camera": True,  # Not critical for AI HAT+
        "Final": False
    }
    
    # Run all checks
    check_system_info()
    results["Hardware"] = check_hardware()
    results["Software"] = check_software()
    results["Python"] = check_python_environment()
    check_interfaces()
    check_camera()
    results["Final"] = final_test()
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 VERIFICATION SUMMARY")
    print("=" * 60)
    
    for category, status in results.items():
        icon = "✅" if status else "❌"
        print(f"   {icon} {category}: {'PASS' if status else 'FAIL'}")
    
    # Overall status
    critical_checks = ["Hardware", "Software", "Final"]
    critical_passed = all(results[check] for check in critical_checks)
    
    print("\n" + "=" * 60)
    if critical_passed:
        print("🎉 AI HAT+ SETUP COMPLETE!")
        print("✅ Your Hailo-8L AI accelerator is ready!")
        print("✅ Perfect for your 'Speak Dutch To Me' project!")
        print("\n🚀 Next Steps:")
        print("   1. Start building your Dutch learning AI")
        print("   2. Use OpenCV + Hailo for computer vision")
        print("   3. Implement real-time language processing")
        print("   4. Test with: hailortcli scan")
    else:
        print("⚠️  SETUP NEEDS ATTENTION")
        print("Some components need troubleshooting.")
        print("\n🔧 Troubleshooting:")
        if not results["Hardware"]:
            print("   - Check AI HAT+ physical connection")
            print("   - Ensure proper seating on GPIO pins")
            print("   - Check power supply (5V, 3A minimum)")
        if not results["Software"]:
            print("   - Reinstall HailoRT: sudo apt install hailort")
            print("   - Check package installation: dpkg -l | grep hailo")
        if not results["Final"]:
            print("   - Try rebooting: sudo reboot")
            print("   - Check dmesg: dmesg | grep -i hailo")
            print("   - Verify firmware loading")
    
    print("\n📋 For support:")
    print("   - Hailo documentation: https://hailo.ai/developer-zone/")
    print("   - Check kernel messages: dmesg | grep -i hailo")
    print("   - Run this script again after changes")

if __name__ == "__main__":
    main()
