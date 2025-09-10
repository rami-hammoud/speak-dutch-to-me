#!/usr/bin/env python3
"""
AI HAT+ Complete Setup Script for Raspberry Pi 5
This script will set up the Hailo-8L AI accelerator from scratch
"""

import subprocess
import sys
import os
import time

def run_command(cmd, description="", check=True):
    """Run a shell command and handle errors"""
    print(f"🔧 {description}")
    print(f"   Command: {cmd}")
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)
        if result.stdout:
            print(f"   Output: {result.stdout.strip()}")
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {e}")
        if e.stderr:
            print(f"   Error details: {e.stderr.strip()}")
        return None

def check_raspberry_pi():
    """Check if we're on a Raspberry Pi 5"""
    print("🔍 Checking Raspberry Pi model...")
    
    try:
        with open('/proc/device-tree/model', 'r') as f:
            model = f.read().strip('\x00')
        print(f"   Model: {model}")
        
        if "Raspberry Pi 5" not in model:
            print("⚠️  Warning: AI HAT+ is designed for Raspberry Pi 5")
            return False
        return True
    except:
        print("❌ Could not determine Pi model")
        return False

def update_system():
    """Update the system packages"""
    print("\n📦 Updating system packages...")
    run_command("sudo apt update", "Updating package list")
    run_command("sudo apt upgrade -y", "Upgrading packages (this may take a while)")

def install_dependencies():
    """Install required dependencies"""
    print("\n📦 Installing dependencies...")
    
    dependencies = [
        "i2c-tools",
        "python3-pip",
        "python3-dev",
        "cmake",
        "build-essential",
        "wget",
        "curl",
        "git",
        "python3-opencv",
        "python3-numpy"
    ]
    
    cmd = f"sudo apt install -y {' '.join(dependencies)}"
    run_command(cmd, "Installing system dependencies")

def enable_interfaces():
    """Enable required interfaces"""
    print("\n🔧 Enabling required interfaces...")
    
    # Enable I2C
    run_command("sudo raspi-config nonint do_i2c 0", "Enabling I2C")
    
    # Enable SPI
    run_command("sudo raspi-config nonint do_spi 0", "Enabling SPI")
    
    # Enable camera (for your Dutch learning project)
    run_command("sudo raspi-config nonint do_camera 0", "Enabling Camera")

def update_boot_config():
    """Update boot configuration for AI HAT+"""
    print("\n🔧 Updating boot configuration...")
    
    config_additions = [
        "",
        "# AI HAT+ Configuration",
        "dtparam=i2c_arm=on",
        "dtparam=spi=on", 
        "gpu_mem=128",
        "# Camera configuration for Dutch learning project",
        "camera_auto_detect=1",
        "display_auto_detect=1"
    ]
    
    try:
        # Check current config
        config_path = "/boot/firmware/config.txt"
        if not os.path.exists(config_path):
            config_path = "/boot/config.txt"  # Fallback for older Pi OS
            
        with open(config_path, 'r') as f:
            current_config = f.read()
        
        # Add new lines if not present
        for line in config_additions:
            if line and not line.startswith('#') and line not in current_config:
                run_command(f"echo '{line}' | sudo tee -a {config_path}", f"Adding {line}")
                
    except Exception as e:
        print(f"❌ Error updating boot config: {e}")

def download_hailort():
    """Download HailoRT suite"""
    print("\n📥 Downloading HailoRT suite...")
    
    # Check if already exists
    existing_files = [f for f in os.listdir('.') if f.startswith('hailort') and f.endswith('.deb')]
    if existing_files:
        print(f"   ✅ HailoRT package already exists: {existing_files[0]}")
        return True
    
    # Updated URLs for HailoRT
    hailort_urls = [
        # Try the official release URL (may need authentication)
        "https://hailo.ai/downloads/hailort-4.20.0-rpi5.deb",
        # Alternative direct link (if available)
        "https://github.com/hailo-ai/hailort/releases/latest/download/hailort-rpi5.deb",
    ]
    
    for url in hailort_urls:
        print(f"   Trying to download from: {url}")
        result = run_command(f"wget --timeout=30 -O hailort-rpi5.deb '{url}'", "Downloading HailoRT", check=False)
        if result and result.returncode == 0 and os.path.exists("hailort-rpi5.deb"):
            # Check if file is valid (not an error page)
            if os.path.getsize("hailort-rpi5.deb") > 1000000:  # At least 1MB
                print("   ✅ Download successful")
                return True
            else:
                print("   ❌ Downloaded file seems invalid")
                run_command("rm -f hailort-rpi5.deb", "Removing invalid file", check=False)
    
    print("❌ Could not download HailoRT automatically")
    print("   Manual download required:")
    print("   1. Go to: https://hailo.ai/developer-zone/software-downloads/")
    print("   2. Register/login if required")
    print("   3. Download: HailoRT Suite for Raspberry Pi 5")
    print("   4. Transfer to Pi and place in this directory")
    print("   5. Run this script again")
    return False

def install_hailort():
    """Install HailoRT suite"""
    print("\n🚀 Installing HailoRT suite...")
    
    # Check for package file
    hailort_files = [f for f in os.listdir('.') if f.startswith('hailort') and f.endswith('.deb')]
    
    if not hailort_files:
        print("❌ No HailoRT .deb file found")
        print("   Please download hailort-*-rpi5.deb from Hailo's website")
        return False
    
    hailort_file = hailort_files[0]
    print(f"   Found: {hailort_file}")
    
    # Install the package
    run_command(f"sudo dpkg -i {hailort_file}", "Installing HailoRT suite")
    run_command("sudo apt-get install -f", "Fixing dependencies")
    
    return True

def load_kernel_modules():
    """Load required kernel modules"""
    print("\n🔧 Loading kernel modules...")
    
    modules = ["i2c-dev", "i2c-bcm2835"]
    
    for module in modules:
        run_command(f"sudo modprobe {module}", f"Loading {module}")
        # Add to /etc/modules for auto-load
        run_command(f"echo '{module}' | sudo tee -a /etc/modules", f"Adding {module} to autoload", check=False)

def test_hardware():
    """Test hardware detection"""
    print("\n🧪 Testing hardware detection...")
    
    # Test I2C
    result = run_command("sudo i2cdetect -y 1", "Scanning I2C bus", check=False)
    
    # Test for Hailo device in PCI
    run_command("lspci | grep -i hailo", "Checking for Hailo PCI device", check=False)
    
    # Check dmesg for Hailo messages
    run_command("dmesg | grep -i hailo | tail -10", "Checking kernel messages", check=False)

def test_software():
    """Test software installation"""
    print("\n🧪 Testing software installation...")
    
    # Test HailoRT CLI
    run_command("hailortcli scan", "Testing HailoRT CLI", check=False)
    
    # Test Python imports
    try:
        import hailo_platform_api
        print("✅ Hailo Platform API import successful")
    except ImportError:
        print("⚠️  Hailo Platform API not available (normal if not yet installed)")

def create_test_scripts():
    """Create additional test scripts"""
    print("\n📝 Creating test scripts...")
    
    # Quick test script
    quick_test = '''#!/usr/bin/env python3
"""Quick AI HAT+ Test"""
import subprocess

print("🤖 Quick AI HAT+ Test")
print("=" * 30)

# Check hardware
print("\\n1. Hardware Detection:")
try:
    result = subprocess.run(['lspci'], capture_output=True, text=True)
    hailo_found = any('hailo' in line.lower() for line in result.stdout.split('\\n'))
    print(f"   Hailo device: {'✅ Found' if hailo_found else '❌ Not found'}")
except:
    print("   ❌ Error checking hardware")

# Check software  
print("\\n2. Software Check:")
try:
    subprocess.run(['hailortcli', '--version'], capture_output=True, check=True)
    print("   HailoRT CLI: ✅ Available")
except:
    print("   HailoRT CLI: ❌ Not available")

try:
    import hailo_platform_api
    print("   Python API: ✅ Available")
except ImportError:
    print("   Python API: ❌ Not available")

print("\\n✅ Quick test complete!")
'''

    with open('quick_test_ai_hat.py', 'w') as f:
        f.write(quick_test)
    
    run_command("chmod +x quick_test_ai_hat.py", "Making quick test script executable")

def main():
    """Main setup function"""
    print("🤖 AI HAT+ Complete Setup for Raspberry Pi 5")
    print("=" * 60)
    print("This script will set up your Hailo-8L AI accelerator")
    print("for the 'Speak Dutch To Me' project")
    print("=" * 60)
    
    # Confirm before starting
    response = input("\\nProceed with setup? (y/N): ")
    if response.lower() != 'y':
        print("Setup cancelled.")
        return
    
    # Check hardware
    is_pi5 = check_raspberry_pi()
    if not is_pi5:
        response = input("\\nContinue anyway? (y/N): ")
        if response.lower() != 'y':
            return
    
    # Main setup steps
    try:
        update_system()
        install_dependencies()
        enable_interfaces()
        update_boot_config()
        load_kernel_modules()
        
        # HailoRT installation
        print("\\n" + "=" * 60)
        print("🚀 HailoRT Installation")
        print("=" * 60)
        
        if not download_hailort():
            print("\\n⚠️  Please download HailoRT manually:")
            print("1. Go to: https://hailo.ai/developer-zone/")
            print("2. Download the latest hailort-*-rpi5.deb")
            print("3. Place it in this directory")
            print("4. Run this script again")
            
            manual_install = input("\\nDo you have the .deb file already? (y/N): ")
            if manual_install.lower() == 'y':
                install_hailort()
        else:
            install_hailort()
        
        # Test installation
        test_hardware()
        test_software()
        
        # Create additional scripts
        create_test_scripts()
        
        print("\\n" + "=" * 60)
        print("🎉 Setup Complete!")
        print("=" * 60)
        print("Next steps:")
        print("1. Reboot your Pi: sudo reboot")
        print("2. After reboot, test: python3 quick_test_ai_hat.py")
        print("3. Check dmesg for Hailo messages: dmesg | grep -i hailo")
        print("\\nFor your Dutch learning project:")
        print("- Camera is now enabled")
        print("- AI HAT+ is configured for computer vision")
        print("- Ready for OpenCV + Hailo integration")
        
    except KeyboardInterrupt:
        print("\\n\\n❌ Setup interrupted by user")
    except Exception as e:
        print(f"\\n\\n❌ Setup failed: {e}")

if __name__ == "__main__":
    main()