"""
Configuration settings for the Pi Assistant
"""

import os
from dataclasses import dataclass
from typing import Optional

@dataclass
class Config:
    """Configuration class for the Pi Assistant"""
    
    # Server settings
    HOST: str = "0.0.0.0"
    PORT: int = 8080
    DEBUG: bool = True
    
    # OpenAI settings
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4"
    
    # Ollama settings
    OLLAMA_HOST: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.2:3b"
    
    # MCP server settings
    MCP_HOST: str = "localhost"
    MCP_PORT: int = 8081
    
    # Audio settings
    AUDIO_INPUT_DEVICE: Optional[str] = None
    AUDIO_OUTPUT_DEVICE: Optional[str] = None
    
    # Camera settings
    CAMERA_ENABLED: bool = True
    CAMERA_WIDTH: int = 640
    CAMERA_HEIGHT: int = 480
    CAMERA_VFLIP: bool = True  # Set to True to flip camera vertically
    CAMERA_HFLIP: bool = True  # Set to True to flip camera horizontally
    FORCE_USB_CAMERA: bool = False  # Set to True to force USB camera over Pi Camera
    USE_AI_HAT_CAMERA: bool = True  # Set to True to enable AI HAT+ (IMX500) camera
    CAMERA_AWB_MODE: int = 3  # Auto White Balance: 0=auto, 1=tungsten, 2=fluorescent, 3=indoor, 4=daylight, 5=cloudy
    
    # Display settings
    FULLSCREEN: bool = True
    SCREEN_WIDTH: int = 800
    SCREEN_HEIGHT: int = 480
    
    # File paths
    DATA_DIR: str = "./data"
    LOGS_DIR: str = "./logs"
    
    def __post_init__(self):
        """Load configuration from environment variables"""
        self.OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", self.OPENAI_API_KEY)
        self.OPENAI_MODEL = os.getenv("OPENAI_MODEL", self.OPENAI_MODEL)
        self.OLLAMA_HOST = os.getenv("OLLAMA_HOST", self.OLLAMA_HOST)
        self.OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", self.OLLAMA_MODEL)
        self.DEBUG = os.getenv("DEBUG", "true").lower() == "true"
        
        # Create directories if they don't exist
        os.makedirs(self.DATA_DIR, exist_ok=True)
        os.makedirs(self.LOGS_DIR, exist_ok=True)

# Global config instance
config = Config()
