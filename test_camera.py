#!/usr/bin/env python3
"""
Camera Test Script for Pi Assistant
Tests both Pi Camera and USB Camera functionality
"""

import logging
import time
import sys

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def test_camera_manager():
    """Test the actual CameraManager from the assistant"""
    logger.info("=== Testing Pi Assistant Camera Manager ===")
    
    try:
        # Add the pi-assistant directory to path
        sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')
        
        from ui.camera_manager import CameraManager
        import asyncio
        
        async def run_camera_test():
            camera_manager = CameraManager()
            logger.info("✓ CameraManager instantiated")
            
            # Check initial status
            logger.info(f"Initial status - Camera available: {camera_manager.camera_available}")
            logger.info(f"Pi Camera available: {camera_manager._pi_camera_available}")
            logger.info(f"OpenCV available: {camera_manager._opencv_available}")
            
            # Initialize camera
            await camera_manager.initialize()
            
            # Check status after initialization
            logger.info(f"After init - Camera available: {camera_manager.camera_available}")
            logger.info(f"Pi Camera active: {camera_manager.pi_camera_available}")
            logger.info(f"USB Camera active: {camera_manager.usb_camera_available}")
            
            if camera_manager.camera_available:
                logger.info("✓ Camera manager initialized successfully")
                
                # Get camera info
                info = camera_manager.get_camera_info()
                logger.info(f"Camera info: {info}")
                
                # Test frame capture
                frame = await camera_manager.get_frame('base64')
                if frame:
                    logger.info("✓ Frame captured via camera manager")
                    logger.info(f"Frame data length: {len(frame) if frame else 0}")
                    return True
                else:
                    logger.error("✗ Failed to get frame via camera manager")
                    return False
            else:
                logger.error("✗ Camera manager - no camera available")
                return False
        
        return asyncio.run(run_camera_test())
        
    except Exception as e:
        logger.error(f"✗ Camera manager test error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_picamera2():
    """Test Pi Camera using picamera2"""
    logger.info("=== Testing Pi Camera (picamera2) ===")
    
    try:
        from picamera2 import Picamera2
        logger.info("✓ Picamera2 import successful")
        
        # Create camera instance
        picam2 = Picamera2()
        logger.info("✓ Picamera2 instance created")
        
        # List available camera configurations
        cameras = Picamera2.global_camera_info()
        logger.info(f"Available cameras: {len(cameras)}")
        
        # Create configuration
        config = picam2.create_preview_configuration(
            main={"size": (640, 480), "format": "RGB888"}
        )
        logger.info("✓ Camera configuration created")
        
        # Configure camera
        picam2.configure(config)
        logger.info("✓ Camera configured")
        
        # Start camera
        picam2.start()
        logger.info("✓ Camera started")
        
        # Capture a frame
        time.sleep(2)  # Let camera settle
        frame = picam2.capture_array()
        logger.info(f"✓ Frame captured: {frame.shape if frame is not None else 'None'}")
        
        # Stop camera
        picam2.stop()
        logger.info("✓ Camera stopped")
        
        picam2.close()
        logger.info("✓ Camera closed")
        
        return True
        
    except ImportError as e:
        logger.error(f"✗ Picamera2 not available: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ Pi Camera error: {e}")
        return False

def test_opencv_camera():
    """Test USB Camera using OpenCV"""
    logger.info("=== Testing USB Camera (OpenCV) ===")
    
    try:
        import cv2
        logger.info("✓ OpenCV import successful")
        
        # Try different camera indices
        for i in range(3):
            logger.info(f"Trying camera index {i}...")
            cap = cv2.VideoCapture(i)
            
            if cap.isOpened():
                logger.info(f"✓ Camera {i} opened successfully")
                
                # Get camera properties
                width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
                height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
                fps = cap.get(cv2.CAP_PROP_FPS)
                logger.info(f"Camera {i} properties: {width}x{height} @ {fps} FPS")
                
                # Try to capture a frame
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
        
        logger.error("✗ No working USB cameras found")
        return False
        
    except ImportError as e:
        logger.error(f"✗ OpenCV not available: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ USB Camera error: {e}")
        return False

def main():
    """Run all camera tests"""
    logger.info("Starting comprehensive camera tests...")
    
    results = {
        'camera_manager': test_camera_manager(),
        'picamera2': test_picamera2(),
        'opencv': test_opencv_camera()
    }
    
    logger.info("=== Test Results Summary ===")
    for test_name, result in results.items():
        status = "PASS" if result else "FAIL"
        logger.info(f"{test_name}: {status}")
    
    # Overall result
    if any(results.values()):
        logger.info("✓ At least one camera method is working")
        return 0
    else:
        logger.error("✗ No camera methods are working")
        return 1

if __name__ == "__main__":
    sys.exit(main())
