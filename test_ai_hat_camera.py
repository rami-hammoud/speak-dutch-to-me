#!/usr/bin/env python3
"""
Quick AI HAT+ Camera Test
Tests the IMX500 camera on AI HAT+ with proper configuration
"""

import os
import sys
import time
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def test_ai_hat_camera():
    """Test AI HAT+ camera specifically"""
    logger.info("=== Testing AI HAT+ (IMX500) Camera ===")
    
    try:
        # Set environment variables for AI HAT+
        os.environ['LIBCAMERA_LOG_LEVELS'] = '*:WARN'
        
        # Check if AI HAT+ tuning file exists
        tuning_file = '/usr/share/libcamera/ipa/rpi/pisp/imx500_ai_hat.json'
        if os.path.exists(tuning_file):
            os.environ['LIBCAMERA_RPI_TUNING_FILE'] = tuning_file
            logger.info("✓ Using AI HAT+ tuning file")
        else:
            logger.warning("AI HAT+ tuning file not found, using default")
        
        # Import picamera2
        from picamera2 import Picamera2
        logger.info("✓ Picamera2 import successful")
        
        # Create camera instance
        picam2 = Picamera2()
        logger.info("✓ Camera instance created")
        
        # Get camera information
        cameras = picam2.global_camera_info()
        logger.info(f"Available cameras: {len(cameras)}")
        for i, cam in enumerate(cameras):
            logger.info(f"  Camera {i}: {cam}")
        
        # Configure camera for AI HAT+
        config = picam2.create_still_configuration(
            main={"size": (640, 480), "format": "RGB888"},
            buffer_count=2
        )
        logger.info("✓ Camera configuration created")
        
        # Apply configuration
        picam2.configure(config)
        logger.info("✓ Camera configured")
        
        # Start camera
        picam2.start()
        logger.info("✓ Camera started")
        
        # Let camera stabilize
        logger.info("Waiting for camera to stabilize...")
        time.sleep(3)
        
        # Capture test image
        test_image = "/tmp/ai_hat_test.jpg"
        picam2.capture_file(test_image)
        logger.info("✓ Image captured")
        
        # Stop camera
        picam2.stop()
        picam2.close()
        logger.info("✓ Camera closed")
        
        # Check captured image
        if os.path.exists(test_image):
            size = os.path.getsize(test_image)
            logger.info(f"✓ Test image created: {size} bytes")
            os.remove(test_image)
            logger.info("AI HAT+ Camera Test: SUCCESS ✓")
            return True
        else:
            logger.error("✗ Test image file not found")
            return False
            
    except ImportError as e:
        logger.error(f"✗ Picamera2 not available: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ AI HAT+ camera test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_camera_manager():
    """Test the Pi Assistant camera manager with AI HAT+"""
    logger.info("=== Testing Pi Assistant Camera Manager with AI HAT+ ===")
    
    try:
        # Add pi-assistant to path
        sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')
        
        from ui.camera_manager import CameraManager
        import asyncio
        
        async def run_test():
            camera_manager = CameraManager()
            logger.info("✓ CameraManager instantiated")
            
            # Check configuration
            from config import config
            logger.info(f"Camera enabled: {config.CAMERA_ENABLED}")
            logger.info(f"Force USB camera: {config.FORCE_USB_CAMERA}")
            logger.info(f"Use AI HAT+ camera: {config.USE_AI_HAT_CAMERA}")
            
            # Initialize camera
            await camera_manager.initialize()
            
            # Check results
            info = camera_manager.get_camera_info()
            logger.info(f"Camera info: {info}")
            
            if camera_manager.camera_available:
                logger.info("✓ Camera manager initialized successfully")
                
                # Test frame capture
                frame = await camera_manager.get_frame('base64')
                if frame:
                    logger.info(f"✓ Frame captured - length: {len(frame)}")
                    logger.info("Camera Manager Test: SUCCESS ✓")
                    
                    # Cleanup
                    await camera_manager.cleanup()
                    return True
                else:
                    logger.error("✗ No frame captured")
            else:
                logger.error("✗ Camera not available")
            
            await camera_manager.cleanup()
            return False
        
        return asyncio.run(run_test())
        
    except Exception as e:
        logger.error(f"✗ Camera manager test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run AI HAT+ camera tests"""
    logger.info("Starting AI HAT+ Camera Tests...")
    
    # Check if we're on a Pi
    try:
        with open('/proc/cpuinfo', 'r') as f:
            if 'Raspberry Pi' not in f.read():
                logger.error("This test should be run on a Raspberry Pi")
                return 1
    except:
        logger.warning("Could not verify Pi hardware")
    
    results = {
        'ai_hat_direct': test_ai_hat_camera(),
        'camera_manager': test_camera_manager()
    }
    
    logger.info("\n=== Test Results ===")
    for test_name, result in results.items():
        status = "PASS ✓" if result else "FAIL ✗"
        logger.info(f"{test_name}: {status}")
    
    if all(results.values()):
        logger.info("\n🎉 All tests passed! AI HAT+ camera is working correctly.")
        logger.info("You can now start the Pi Assistant:")
        logger.info("  cd pi-assistant && python3 main.py")
        return 0
    elif results['ai_hat_direct']:
        logger.info("\n⚠️  AI HAT+ hardware works but camera manager has issues.")
        logger.info("Try running the Pi Assistant - it may still work.")
        return 0
    else:
        logger.error("\n❌ AI HAT+ camera tests failed.")
        logger.info("Run the fix script first: ./fix_ai_hat_camera.sh")
        return 1

if __name__ == "__main__":
    sys.exit(main())
