# test_ai_hat.py
import subprocess
import sys

def test_ai_hat():
    print("🔍 Testing AI HAT+ connectivity...")
    
    try:
        # Check I2C devices
        result = subprocess.run(['i2cdetect', '-y', '1'], 
                              capture_output=True, text=True)
        print("I2C devices found:")
        print(result.stdout)
        
        # Try importing hailo libraries (if installed)
        try:
            import hailo_platform_api as hailo
            print("✅ Hailo platform API available")
        except ImportError:
            print("⚠️  Hailo platform API not installed")
            
    except Exception as e:
        print(f"❌ Error testing AI HAT+: {e}")

if __name__ == "__main__":
    test_ai_hat()