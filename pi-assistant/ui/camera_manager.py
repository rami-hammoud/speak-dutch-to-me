"""
Camera Manager for Pi Assistant
Handles camera operations including capture, streaming, and basic computer vision
"""

import asyncio
import logging
import base64
import io
import time
from typing import Optional, Tuple, Any
import threading
import queue

try:
    import cv2
    import numpy as np
    OPENCV_AVAILABLE = True
except ImportError:
    OPENCV_AVAILABLE = False

try:
    from picamera2 import Picamera2
    PI_CAMERA_AVAILABLE = True
except ImportError:
    PI_CAMERA_AVAILABLE = False

from config import config

logger = logging.getLogger(__name__)

class CameraManager:
    """Manages camera operations and computer vision"""
    
    def __init__(self):
        self.camera = None
        self.picamera = None  # Separate reference for Pi Camera
        self.is_streaming = False
        self.frame_queue = queue.Queue(maxsize=5)
        self.current_frame = None
        self.capture_thread = None
        
        # Camera settings
        self.width = config.CAMERA_WIDTH
        self.height = config.CAMERA_HEIGHT
        self.fps = 30
        
        # Detection settings
        self.face_cascade = None
        self.object_cascade = None
        
        # Status flags
        self._pi_camera_available = PI_CAMERA_AVAILABLE
        self._opencv_available = OPENCV_AVAILABLE
    
    async def initialize(self):
        """Initialize camera"""
        if not config.CAMERA_ENABLED:
            logger.info("Camera disabled in config")
            return
        
        try:
            # Try to initialize Pi Camera first
            if self._pi_camera_available:
                try:
                    self.picamera = Picamera2()
                    
                    # Configure camera with basic settings
                    camera_config = self.picamera.create_preview_configuration(
                        main={"size": (self.width, self.height), "format": "RGB888"}
                    )
                    
                    # Configure without transform attribute (causes errors on some setups)
                    self.picamera.configure(camera_config)
                    
                    # Start camera
                    self.picamera.start()
                    
                    # Wait for camera to stabilize
                    time.sleep(2)
                    
                    # Set main camera reference
                    self.camera = self.picamera
                    
                    logger.info("Pi Camera initialized successfully")
                    
                except Exception as e:
                    logger.warning(f"Pi Camera initialization failed: {e}")
                    self.picamera = None
                    self.camera = None
                    self._pi_camera_available = False  # Don't try again this session
            
            # Fallback to USB camera
            if not self.camera and self._opencv_available:
                try:
                    usb_camera = cv2.VideoCapture(0)
                    
                    if usb_camera.isOpened():
                        # Set camera properties
                        usb_camera.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
                        usb_camera.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
                        usb_camera.set(cv2.CAP_PROP_FPS, self.fps)
                        
                        # Set main camera reference
                        self.camera = usb_camera
                        
                        logger.info("USB Camera initialized successfully")
                    else:
                        usb_camera.release()
                        
                except Exception as e:
                    logger.warning(f"USB Camera initialization failed: {e}")
                    if 'usb_camera' in locals():
                        usb_camera.release()
            
            # Initialize computer vision components
            if self._opencv_available:
                try:
                    # Load face detection cascade
                    self.face_cascade = cv2.CascadeClassifier(
                        cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
                    )
                    logger.info("Face detection initialized")
                    
                except Exception as e:
                    logger.warning(f"Face detection initialization failed: {e}")
            
            if self.camera:
                logger.info("Camera manager initialized successfully")
            else:
                logger.warning("No camera available")
                
        except Exception as e:
            logger.error(f"Camera initialization error: {e}")
    
    async def start_streaming(self):
        """Start camera streaming"""
        if not self.camera:
            raise Exception("Camera not available")
        
        if self.is_streaming:
            return
        
        self.is_streaming = True
        
        # Start capture thread
        self.capture_thread = threading.Thread(target=self._capture_loop)
        self.capture_thread.daemon = True
        self.capture_thread.start()
        
        logger.info("Camera streaming started")
    
    async def stop_streaming(self):
        """Stop camera streaming"""
        self.is_streaming = False
        
        if self.capture_thread:
            self.capture_thread.join(timeout=5)
            self.capture_thread = None
        
        logger.info("Camera streaming stopped")
    
    def _capture_loop(self):
        """Camera capture loop running in separate thread"""
        while self.is_streaming:
            try:
                frame = self._capture_frame()
                if frame is not None:
                    # Update current frame
                    self.current_frame = frame
                    
                    # Add to queue (non-blocking)
                    try:
                        self.frame_queue.put_nowait(frame)
                    except queue.Full:
                        # Remove oldest frame if queue is full
                        try:
                            self.frame_queue.get_nowait()
                            self.frame_queue.put_nowait(frame)
                        except queue.Empty:
                            pass
                
                time.sleep(1.0 / self.fps)  # Control frame rate
                
            except Exception as e:
                logger.error(f"Frame capture error: {e}")
                time.sleep(1)  # Wait before retrying
    
    def _capture_frame(self) -> Optional[np.ndarray]:
        """Capture a single frame from camera"""
        if not self._opencv_available:
            return None
            
        try:
            if self.picamera and isinstance(self.picamera, Picamera2):
                # Pi Camera capture
                frame = self.picamera.capture_array()
                if frame is not None:
                    # Convert from RGB to BGR for OpenCV compatibility
                    if len(frame.shape) == 3 and frame.shape[2] == 3:
                        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
                return frame
                
            elif self.camera and hasattr(self.camera, 'read'):
                # USB Camera capture
                ret, frame = self.camera.read()
                if ret:
                    return frame
                
        except Exception as e:
            logger.error(f"Frame capture error: {e}")
        
        return None
    
    async def get_frame(self, format='base64') -> Optional[str]:
        """Get current camera frame"""
        if not self.camera:
            return None
        
        try:
            # Start streaming if not already started
            if not self.is_streaming:
                await self.start_streaming()
                # Wait a bit for first frame
                await asyncio.sleep(0.1)
            
            frame = self.current_frame
            if frame is None:
                return None
            
            if format == 'base64':
                # Encode frame as JPEG and convert to base64
                _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                frame_base64 = base64.b64encode(buffer).decode('utf-8')
                return f"data:image/jpeg;base64,{frame_base64}"
            
            return frame
            
        except Exception as e:
            logger.error(f"Get frame error: {e}")
            return None
    
    async def capture_image(self, filename: Optional[str] = None) -> Optional[str]:
        """Capture and save an image"""
        if not self.camera:
            raise Exception("Camera not available")
        
        try:
            frame = self._capture_frame()
            if frame is None:
                raise Exception("Failed to capture frame")
            
            if filename is None:
                filename = f"capture_{int(time.time())}.jpg"
            
            # Save image
            cv2.imwrite(filename, frame)
            
            logger.info(f"Image captured: {filename}")
            return filename
            
        except Exception as e:
            logger.error(f"Image capture error: {e}")
            raise e
    
    async def detect_faces(self, frame: Optional[np.ndarray] = None) -> list:
        """Detect faces in frame"""
        if not self._opencv_available or not self.face_cascade:
            return []
        
        try:
            if frame is None:
                frame = self.current_frame
            
            if frame is None:
                return []
            
            # Convert to grayscale for face detection
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            
            # Detect faces
            faces = self.face_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(30, 30)
            )
            
            # Convert to list of dictionaries
            face_list = []
            for (x, y, w, h) in faces:
                face_list.append({
                    'x': int(x),
                    'y': int(y),
                    'width': int(w),
                    'height': int(h),
                    'confidence': 1.0  # Haar cascades don't provide confidence
                })
            
            return face_list
            
        except Exception as e:
            logger.error(f"Face detection error: {e}")
            return []
    
    async def get_frame_with_annotations(self, include_faces: bool = True) -> Optional[str]:
        """Get frame with computer vision annotations"""
        if not self._opencv_available or not self.camera:
            return await self.get_frame()
        
        try:
            frame = self.current_frame
            if frame is None:
                return None
            
            # Make a copy for annotations
            annotated_frame = frame.copy()
            
            # Add face detection
            if include_faces:
                faces = await self.detect_faces(frame)
                for face in faces:
                    x, y, w, h = face['x'], face['y'], face['width'], face['height']
                    cv2.rectangle(annotated_frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
                    cv2.putText(
                        annotated_frame, 
                        'Face', 
                        (x, y - 10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 
                        0.5, 
                        (0, 255, 0), 
                        1
                    )
            
            # Encode as base64
            _, buffer = cv2.imencode('.jpg', annotated_frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            frame_base64 = base64.b64encode(buffer).decode('utf-8')
            return f"data:image/jpeg;base64,{frame_base64}"
            
        except Exception as e:
            logger.error(f"Annotated frame error: {e}")
            return await self.get_frame()
    
    def get_camera_info(self) -> dict:
        """Get camera information"""
        info = {
            "available": self.camera_available,
            "streaming": self.is_streaming,
            "width": self.width,
            "height": self.height,
            "fps": self.fps,
            "type": None,
            "pi_camera": self.pi_camera_available,
            "usb_camera": self.usb_camera_available
        }
        
        if self.picamera:
            info["type"] = "Pi Camera"
        elif self.camera and hasattr(self.camera, 'read'):
            info["type"] = "USB Camera"
        
        return info
    
    @property
    def camera_available(self) -> bool:
        """Check if any camera is available"""
        return self.camera is not None
    
    @property
    def pi_camera_available(self) -> bool:
        """Check if Pi Camera is available"""
        return self._pi_camera_available and self.picamera is not None
    
    @property
    def usb_camera_available(self) -> bool:
        """Check if USB Camera is available"""
        return self._opencv_available and self.camera is not None and self.picamera is None
    
    async def cleanup(self):
        """Cleanup camera resources"""
        try:
            await self.stop_streaming()
            
            if self.picamera:
                try:
                    self.picamera.stop()
                    self.picamera.close()
                except:
                    pass
                self.picamera = None
                
            if self.camera and hasattr(self.camera, 'release'):
                try:
                    self.camera.release()
                except:
                    pass
                
            self.camera = None
            
            # Clear frame queue
            while not self.frame_queue.empty():
                try:
                    self.frame_queue.get_nowait()
                except queue.Empty:
                    break
            
            logger.info("Camera manager cleanup complete")
            
        except Exception as e:
            logger.error(f"Camera cleanup error: {e}")
