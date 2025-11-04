"""
Reusable Text-to-Speech Service
Supports multiple backends: OpenAI TTS, Google TTS, pyttsx3, Web Speech API
"""

import asyncio
import logging
import io
from typing import Optional, List, Dict, Any
from abc import ABC, abstractmethod
from pathlib import Path
import tempfile

logger = logging.getLogger(__name__)

# Try to import TTS libraries
try:
    import pyttsx3
    PYTTSX3_AVAILABLE = True
except ImportError:
    PYTTSX3_AVAILABLE = False
    logger.warning("pyttsx3 not installed: pip install pyttsx3")

try:
    from gtts import gTTS
    GTTS_AVAILABLE = True
except ImportError:
    GTTS_AVAILABLE = False
    logger.warning("gTTS not installed: pip install gtts")

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logger.warning("openai not installed: pip install openai")

try:
    import pygame
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False


class TTSBackend(ABC):
    """Abstract base class for Text-to-Speech backends"""
    
    @abstractmethod
    async def speak(self, text: str, language: str = "en-US", save_to: Optional[str] = None) -> Optional[bytes]:
        """Convert text to speech"""
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Check if backend is available"""
        pass
    
    @abstractmethod
    def get_voices(self) -> List[Dict[str, str]]:
        """Get available voices"""
        pass


class OpenAITTSBackend(TTSBackend):
    """OpenAI TTS - Best quality, most natural"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        self.client = None
        if api_key and OPENAI_AVAILABLE:
            self.client = openai.OpenAI(api_key=api_key)
    
    async def speak(self, text: str, language: str = "en-US", save_to: Optional[str] = None) -> Optional[bytes]:
        """Convert text to speech using OpenAI TTS"""
        if not self.client:
            return None
        
        try:
            # OpenAI TTS supports multiple voices
            voice = "alloy"  # Default voice (can be: alloy, echo, fable, onyx, nova, shimmer)
            
            # Generate speech
            response = await asyncio.to_thread(
                self.client.audio.speech.create,
                model="tts-1",
                voice=voice,
                input=text
            )
            
            # Get audio data
            audio_data = response.content
            
            # Save to file if requested
            if save_to:
                with open(save_to, "wb") as f:
                    f.write(audio_data)
            
            return audio_data
            
        except Exception as e:
            logger.error(f"OpenAI TTS error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.client is not None
    
    def get_voices(self) -> List[Dict[str, str]]:
        return [
            {"id": "alloy", "name": "Alloy", "gender": "neutral"},
            {"id": "echo", "name": "Echo", "gender": "male"},
            {"id": "fable", "name": "Fable", "gender": "neutral"},
            {"id": "onyx", "name": "Onyx", "gender": "male"},
            {"id": "nova", "name": "Nova", "gender": "female"},
            {"id": "shimmer", "name": "Shimmer", "gender": "female"},
        ]


class GoogleTTSBackend(TTSBackend):
    """Google TTS - Good quality, free"""
    
    def __init__(self):
        self.available = GTTS_AVAILABLE
    
    async def speak(self, text: str, language: str = "en-US", save_to: Optional[str] = None) -> Optional[bytes]:
        """Convert text to speech using Google TTS"""
        if not self.available:
            return None
        
        try:
            # Extract language code (en-US -> en, nl-NL -> nl)
            lang_code = language.split("-")[0]
            
            # Generate speech
            tts = gTTS(text=text, lang=lang_code, slow=False)
            
            # Save to bytes
            audio_io = io.BytesIO()
            await asyncio.to_thread(tts.write_to_fp, audio_io)
            audio_data = audio_io.getvalue()
            
            # Save to file if requested
            if save_to:
                with open(save_to, "wb") as f:
                    f.write(audio_data)
            
            return audio_data
            
        except Exception as e:
            logger.error(f"Google TTS error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.available
    
    def get_voices(self) -> List[Dict[str, str]]:
        return [
            {"id": "default", "name": "Default", "gender": "neutral"}
        ]


class Pyttsx3Backend(TTSBackend):
    """pyttsx3 - Local, offline, robotic quality"""
    
    def __init__(self):
        self.engine = None
        if PYTTSX3_AVAILABLE:
            try:
                self.engine = pyttsx3.init()
                # Configure engine
                self.engine.setProperty('rate', 150)
                self.engine.setProperty('volume', 0.9)
            except Exception as e:
                logger.error(f"Failed to initialize pyttsx3: {e}")
                self.engine = None
    
    async def speak(self, text: str, language: str = "en-US", save_to: Optional[str] = None) -> Optional[bytes]:
        """Convert text to speech using pyttsx3"""
        if not self.engine:
            return None
        
        try:
            # Save to file if requested
            if save_to:
                await asyncio.to_thread(self.engine.save_to_file, text, save_to)
                await asyncio.to_thread(self.engine.runAndWait)
                
                # Read file back to bytes
                with open(save_to, "rb") as f:
                    return f.read()
            else:
                # Create temp file
                with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                    tmp_path = tmp.name
                
                await asyncio.to_thread(self.engine.save_to_file, text, tmp_path)
                await asyncio.to_thread(self.engine.runAndWait)
                
                # Read and delete
                with open(tmp_path, "rb") as f:
                    audio_data = f.read()
                Path(tmp_path).unlink()
                
                return audio_data
            
        except Exception as e:
            logger.error(f"pyttsx3 TTS error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.engine is not None
    
    def get_voices(self) -> List[Dict[str, str]]:
        if not self.engine:
            return []
        
        try:
            voices = self.engine.getProperty('voices')
            return [
                {
                    "id": voice.id,
                    "name": voice.name,
                    "gender": getattr(voice, "gender", "unknown")
                }
                for voice in voices
            ]
        except:
            return []


class WebSpeechTTSBackend(TTSBackend):
    """Web Speech API TTS - Browser-based (frontend only)"""
    
    def __init__(self):
        # Placeholder for consistency
        pass
    
    async def speak(self, text: str, language: str = "en-US", save_to: Optional[str] = None) -> Optional[bytes]:
        """Web Speech API TTS runs in browser"""
        logger.warning("Web Speech API TTS should be used in browser, not on server")
        return None
    
    def is_available(self) -> bool:
        return False
    
    def get_voices(self) -> List[Dict[str, str]]:
        return []


class TextToSpeechService:
    """
    Reusable Text-to-Speech Service
    
    Supports multiple backends with automatic fallback:
    1. OpenAI TTS (best quality, costs money)
    2. Google TTS (good quality, free, requires internet)
    3. pyttsx3 (local, offline, robotic)
    4. Web Speech API (browser-based)
    
    Example usage:
        service = TextToSpeechService()
        await service.initialize(openai_api_key="sk-...")
        
        # Generate speech
        audio = await service.speak("Hello world", language="en-US")
        
        # Save to file
        await service.speak("Goedemorgen", language="nl-NL", save_to="hello.mp3")
        
        # Get available voices
        voices = service.get_voices()
    """
    
    def __init__(self):
        self.backends: Dict[str, TTSBackend] = {}
        self.preferred_backend = "google"
        self.fallback_order = ["openai", "google", "pyttsx3"]
        self.current_voice = None
    
    async def initialize(
        self,
        openai_api_key: Optional[str] = None,
        preferred_backend: str = "google"
    ):
        """Initialize TTS service"""
        logger.info("Initializing Text-to-Speech Service...")
        
        # Initialize backends
        self.backends["openai"] = OpenAITTSBackend(openai_api_key)
        self.backends["google"] = GoogleTTSBackend()
        self.backends["pyttsx3"] = Pyttsx3Backend()
        self.backends["webspeech"] = WebSpeechTTSBackend()
        
        # Set preferred backend
        self.preferred_backend = preferred_backend
        
        # Log available backends
        available = [name for name, backend in self.backends.items() if backend.is_available()]
        logger.info(f"Available TTS backends: {available}")
        
        if not available:
            logger.warning("No TTS backends available!")
        
        return self
    
    def get_available_backends(self) -> List[str]:
        """Get list of available backends"""
        return [name for name, backend in self.backends.items() if backend.is_available()]
    
    async def speak(
        self,
        text: str,
        language: str = "en-US",
        backend: Optional[str] = None,
        save_to: Optional[str] = None,
        voice: Optional[str] = None
    ) -> Optional[bytes]:
        """
        Convert text to speech
        
        Args:
            text: Text to convert to speech
            language: Language code (e.g., "en-US", "nl-NL")
            backend: Specific backend to use (optional)
            save_to: File path to save audio (optional)
            voice: Voice ID to use (optional)
        
        Returns:
            Audio data as bytes or None
        """
        # Determine which backends to try
        backends_to_try = []
        if backend and backend in self.backends:
            backends_to_try = [backend]
        else:
            # Try preferred backend first, then fallbacks
            backends_to_try = [self.preferred_backend] + [
                b for b in self.fallback_order if b != self.preferred_backend
            ]
        
        # Try each backend until one succeeds
        for backend_name in backends_to_try:
            backend_instance = self.backends.get(backend_name)
            if not backend_instance or not backend_instance.is_available():
                continue
            
            logger.info(f"Trying TTS with {backend_name}...")
            try:
                result = await backend_instance.speak(text, language, save_to)
                if result:
                    logger.info(f"TTS successful with {backend_name}")
                    return result
            except Exception as e:
                logger.error(f"Backend {backend_name} failed: {e}")
                continue
        
        logger.warning("All TTS backends failed")
        return None
    
    def get_voices(self, backend: Optional[str] = None) -> List[Dict[str, str]]:
        """Get available voices"""
        if backend and backend in self.backends:
            return self.backends[backend].get_voices()
        
        # Get voices from all available backends
        all_voices = []
        for name, backend_instance in self.backends.items():
            if backend_instance.is_available():
                voices = backend_instance.get_voices()
                for voice in voices:
                    voice["backend"] = name
                all_voices.extend(voices)
        
        return all_voices
    
    def set_voice(self, voice_id: str):
        """Set the current voice"""
        self.current_voice = voice_id
    
    async def speak_with_playback(self, text: str, language: str = "en-US"):
        """Speak text and play it immediately"""
        audio_data = await self.speak(text, language)
        if audio_data:
            # TODO: Implement audio playback
            # For now, just return the audio data
            return audio_data
        return None
    
    def get_backend_info(self) -> Dict[str, Any]:
        """Get information about available backends"""
        return {
            name: {
                "available": backend.is_available(),
                "type": type(backend).__name__,
                "voices": backend.get_voices()
            }
            for name, backend in self.backends.items()
        }


# Convenience function
async def create_tts_service(
    openai_api_key: Optional[str] = None,
    preferred: str = "google"
) -> TextToSpeechService:
    """Create and initialize TTS service"""
    service = TextToSpeechService()
    await service.initialize(openai_api_key, preferred)
    return service
