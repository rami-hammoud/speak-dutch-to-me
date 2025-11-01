#!/usr/bin/env python3
"""
Camera Color Diagnostic Tool
Captures a frame and saves it in multiple formats to compare
"""

import sys
sys.path.insert(0, '/home/rami/workspace/speak-dutch-to-me/pi-assistant')

from picamera2 import Picamera2
import cv2
import numpy as np
from libcamera import Transform

def main():
    print("=== Camera Color Diagnostic ===\n")
    
    # Initialize camera
    print("Initializing IMX500 camera...")
    picam = Picamera2()
    
    # Configure with flip
    transform = Transform(vflip=1, hflip=1)
    config = picam.create_preview_configuration(
        main={"size": (640, 480), "format": "RGB888"},
        buffer_count=3,
        transform=transform
    )
    picam.configure(config)
    picam.start()
    
    print("Camera started, waiting 2 seconds...")
    import time
    time.sleep(2)
    
    # Capture frame
    print("Capturing frame...")
    frame_rgb = picam.capture_array()
    
    print(f"Frame shape: {frame_rgb.shape}")
    print(f"Frame dtype: {frame_rgb.dtype}")
    print(f"Frame range: {frame_rgb.min()} to {frame_rgb.max()}")
    
    # Save in different formats
    print("\nSaving test images...")
    
    # 1. Raw RGB (what camera outputs)
    cv2.imwrite('/home/rami/test_raw_rgb.jpg', frame_rgb)
    print("✓ test_raw_rgb.jpg - Camera output as-is (RGB treated as BGR by cv2)")
    
    # 2. RGB to BGR conversion (what we do in code)
    frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
    cv2.imwrite('/home/rami/test_converted_bgr.jpg', frame_bgr)
    print("✓ test_converted_bgr.jpg - After RGB to BGR conversion")
    
    # 3. No conversion (direct save with OpenCV)
    # Note: cv2.imwrite expects BGR, so if we give RGB it will look wrong
    cv2.imwrite('/home/rami/test_no_conversion.jpg', frame_rgb)
    print("✓ test_no_conversion.jpg - RGB saved directly (should look wrong)")
    
    # 4. Manual channel swap
    frame_swapped = frame_rgb[:, :, ::-1].copy()
    cv2.imwrite('/home/rami/test_channel_swap.jpg', frame_swapped)
    print("✓ test_channel_swap.jpg - Manually swapped channels")
    
    # Sample pixel values
    print("\n=== Sample Pixel (center of image) ===")
    y, x = 240, 320
    print(f"RGB values at center pixel ({x},{y}):")
    print(f"  Original RGB: R={frame_rgb[y,x,0]} G={frame_rgb[y,x,1]} B={frame_rgb[y,x,2]}")
    print(f"  After conversion BGR: B={frame_bgr[y,x,0]} G={frame_bgr[y,x,1]} R={frame_bgr[y,x,2]}")
    
    picam.stop()
    picam.close()
    
    print("\n=== Test Complete ===")
    print("Compare the images:")
    print("  scp rami@voice-assistant:~/test_*.jpg ~/Downloads/")
    print("\nWhich image looks correct? That tells us what conversion to use!")

if __name__ == "__main__":
    main()
