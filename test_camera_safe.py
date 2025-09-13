#!/usr/bin/env python3
"""
Safe Camera Test Script for Pi Assistant
Handles libcamera crashes and provides workarounds
"""

import logging
import time
import sys
import subprocess
import signal
import os

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def safe_test_with_timeout(func, timeout=10):
    """Run a test function with timeout protection"""
    try:
        # Use subprocess to isolate potential crashes
        import multiprocessing
        
        def target():
            try:
                return func()
            except Exception as e:
                logger.error(f"Function error: {e}")
                return False
        
        process = multiprocessing.Process(target=target)
        process.start()
        process.join(timeout=timeout)
        
        if process.is_alive():
            logger.warning(f"Test timed out after {timeout} seconds")
            process.terminate()
            process.join()
            return False
        
        return process.exitcode == 0
        
    except Exception as e:
        logger.error(f"Safe test error: {e}")
        return False

def test_libcamera_hello():
    """Test libcamera using command line tools"""
    logger.info("=== Testing libcamera command line tools ===")
    
    try:
        # Test libcamera-hello with timeout
        logger.info("Testing libcamera-hello --list-cameras...")
        result = subprocess.run(
            ['libcamera-hello', '--list-cameras'], 
            capture_output=True, 
            text=True, 
            timeout=5
        )
        
        if result.returncode == 0:
            logger.info("✓ libcamera-hello list cameras successful")
            logger.info(f"Output: {result.stdout}")
        else:
            logger.warning(f"✗ libcamera-hello failed: {result.stderr}")
            
    except subprocess.TimeoutExpired:
        logger.error("✗ libcamera-hello timed out")
    except FileNotFoundError:
        logger.error("✗ libcamera-hello not found")
    except Exception as e:
        logger.error(f"✗ libcamera-hello error: {e}")
        
    try:
        # Test simple capture with timeout
        logger.info("Testing libcamera-still capture...")
        result = subprocess.run(
            ['libcamera-still', '-o', '/tmp/test_libcam.jpg', '--nopreview', '--immediate'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and os.path.exists('/tmp/test_libcam.jpg'):
            logger.info("✓ libcamera-still capture successful")
            os.remove('/tmp/test_libcam.jpg')
            return True
        else:
            logger.warning(f"✗ libcamera-still failed: {result.stderr}")
            
    except subprocess.TimeoutExpired:
        logger.error("✗ libcamera-still timed out")
    except Exception as e:
        logger.error(f"✗ libcamera-still error: {e}")
        
    return False

def test_opencv_camera_safe():
    """Test OpenCV camera with crash protection"""
    logger.info("=== Testing OpenCV Camera (Safe) ===")
    
    try:
        import cv2
        logger.info("✓ OpenCV import successful")
        
        # Try different camera indices with timeout protection
        for i in range(3):
            logger.info(f"Trying camera index {i}...")
            
            try:
                cap = cv2.VideoCapture(i)
                
                if cap.isOpened():
                    logger.info(f"✓ Camera {i} opened successfully")
                    
                    # Get camera properties
                    width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
                    height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
                    fps = cap.get(cv2.CAP_PROP_FPS)
                    logger.info(f"Camera {i} properties: {width}x{height} @ {fps} FPS")
                    
                    # Try to capture a frame with timeout
                    ret, frame = cap.read()
                    if ret and frame is not None:
                        logger.info(f"✓ Frame captured from camera {i}: {frame.shape}")
                        cap.release()
                        return True
                    else:
                        logger.warning(f"✗ Failed to capture frame from camera {i}")
                    
                    cap.release()
                else:
                    logger.warning(f"✗ Could not open camera {i}")
                    
            except Exception as e:
                logger.error(f"Camera {i} error: {e}")
                
        logger.error("✗ No working USB cameras found")
        return False
        
    except ImportError as e:
        logger.error(f"✗ OpenCV not available: {e}")
        return False

def test_camera_manager_safe():
    """Test camera manager with isolation"""
    logger.info("=== Testing Pi Assistant Camera Manager (Safe) ===")
    
    # Create a separate test script to avoid crashes affecting main process
    test_script = '''
import sys
import asyncio
sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')

async def test_manager():
    try:
        from ui.camera_manager import CameraManager
        
        camera_manager = CameraManager()
        print("✓ CameraManager instantiated")
        
        print(f"Initial - Pi Camera available: {camera_manager._pi_camera_available}")
        print(f"Initial - OpenCV available: {camera_manager._opencv_available}")
        
        # Try to initialize with USB camera only to avoid Pi Camera crash
        camera_manager._pi_camera_available = False  # Force USB camera
        
        await camera_manager.initialize()
        
        print(f"After init - Camera available: {camera_manager.camera_available}")
        print(f"Camera type: {camera_manager.get_camera_info()['type']}")
        
        if camera_manager.camera_available:
            frame = await camera_manager.get_frame('base64')
            if frame:
                print("✓ Frame captured successfully")
                return True
            else:
                print("✗ No frame captured")
                
        await camera_manager.cleanup()
        return False
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    result = asyncio.run(test_manager())
    sys.exit(0 if result else 1)
'''
    
    try:
        with open('/tmp/test_camera_manager.py', 'w') as f:
            f.write(test_script)
        
        result = subprocess.run(
            ['python3', '/tmp/test_camera_manager.py'],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        logger.info(f"Camera manager test output:\n{result.stdout}")
        if result.stderr:
            logger.warning(f"Camera manager errors:\n{result.stderr}")
            
        os.remove('/tmp/test_camera_manager.py')
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        logger.error("✗ Camera manager test timed out")
        return False
    except Exception as e:
        logger.error(f"✗ Camera manager test error: {e}")
        return False

def check_camera_hardware():
    """Check camera hardware detection"""
    logger.info("=== Camera Hardware Detection ===")
    
    # Check video devices
    try:
        video_devices = subprocess.run(['ls', '/dev/video*'], capture_output=True, text=True)
        if video_devices.returncode == 0:
            logger.info(f"Video devices found: {video_devices.stdout.strip()}")
        else:
            logger.warning("No video devices found")
    except:
        logger.warning("Could not check video devices")
    
    # Check media devices
    try:
        media_devices = subprocess.run(['ls', '/dev/media*'], capture_output=True, text=True)
        if media_devices.returncode == 0:
            logger.info(f"Media devices found: {media_devices.stdout.strip()}")
        else:
            logger.warning("No media devices found")
    except:
        logger.warning("Could not check media devices")
    
    # Check I2C devices
    try:
        i2c_result = subprocess.run(['i2cdetect', '-y', '1'], capture_output=True, text=True)
        if i2c_result.returncode == 0:
            logger.info("I2C scan completed")
            if '1a' in i2c_result.stdout:
                logger.info("✓ IMX500 camera detected on I2C address 0x1a")
            else:
                logger.warning("IMX500 camera not detected on expected I2C address")
    except:
        logger.warning("Could not scan I2C devices")

def main():
    """Run safe camera tests"""
    logger.info("Starting safe camera tests...")
    
    # Check hardware first
    check_camera_hardware()
    
    results = {
        'libcamera_cli': test_libcamera_hello(),
        'opencv_safe': test_opencv_camera_safe(),
        'camera_manager_safe': test_camera_manager_safe()
    }
    
    logger.info("=== Test Results Summary ===")
    for test_name, result in results.items():
        status = "PASS" if result else "FAIL"
        logger.info(f"{test_name}: {status}")
    
    # Provide recommendations
    logger.info("\n=== Recommendations ===")
    if not any(results.values()):
        logger.error("All camera tests failed!")
        logger.info("Try these fixes:")
        logger.info("1. Update libcamera: sudo apt update && sudo apt upgrade libcamera*")
        logger.info("2. Disable Pi Camera and use USB only: edit config.py set CAMERA_ENABLED=True but force USB")
        logger.info("3. Check camera connections and reboot")
    elif results['opencv_safe'] and not results['libcamera_cli']:
        logger.info("USB Camera works but Pi Camera has issues")
        logger.info("Recommend using USB camera as primary")
    else:
        logger.info("At least one camera method is working")
    
    return 0 if any(results.values()) else 1

if __name__ == "__main__":
    sys.exit(main())
