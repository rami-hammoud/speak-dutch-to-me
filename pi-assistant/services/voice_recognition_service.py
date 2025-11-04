"""
Reusable Voice Recognition Service
Supports multiple backends: Whisper, Vosk, Google, Web Speech API
"""

import asyncio
import logging
import io
import wave
import json
from typing import Optional, List, Dict, Any, Callable
from abc import ABC, abstractmethod
from pathlib import Path
import tempfile

logger = logging.getLogger(__name__)

# Try to import various speech recognition libraries
try:
    import speech_recognition as sr
    SR_AVAILABLE = True
except ImportError:
    SR_AVAILABLE = False
    logger.warning("speech_recognition not installed: pip install SpeechRecognition")

try:
    from vosk import Model, KaldiRecognizer
    VOSK_AVAILABLE = True
except ImportError:
    VOSK_AVAILABLE = False
    logger.warning("vosk not installed: pip install vosk")

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logger.warning("openai not installed: pip install openai")

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False


class VoiceRecognitionBackend(ABC):
    """Abstract base class for voice recognition backends"""
    
    @abstractmethod
    async def recognize(self, audio_data: bytes, language: str = "en-US") -> Optional[str]:
        """Recognize speech from audio data"""
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Check if backend is available"""
        pass


class WhisperBackend(VoiceRecognitionBackend):
    """OpenAI Whisper API backend - Most accurate"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        self.client = None
        if api_key and OPENAI_AVAILABLE:
            self.client = openai.OpenAI(api_key=api_key)
    
    async def recognize(self, audio_data: bytes, language: str = "en-US") -> Optional[str]:
        """Recognize speech using Whisper API"""
        if not self.client:
            return None
        
        try:
            # Whisper expects a file, so write to temp file
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
                temp_audio.write(audio_data)
                temp_path = temp_audio.name
            
            # Map language codes (en-US -> en, nl-NL -> nl)
            whisper_lang = language.split("-")[0]
            
            # Transcribe using Whisper
            with open(temp_path, "rb") as audio_file:
                transcript = await asyncio.to_thread(
                    self.client.audio.transcriptions.create,
                    model="whisper-1",
                    file=audio_file,
                    language=whisper_lang
                )
            
            # Clean up temp file
            Path(temp_path).unlink()
            
            return transcript.text
            
        except Exception as e:
            logger.error(f"Whisper recognition error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.client is not None


class VoskBackend(VoiceRecognitionBackend):
    """Vosk local speech recognition - Offline, fast"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.model_path = model_path or "/opt/vosk-models/vosk-model-small-en-us-0.15"
        
        if VOSK_AVAILABLE and Path(self.model_path).exists():
            try:
                self.model = Model(self.model_path)
                logger.info(f"Vosk model loaded from {self.model_path}")
            except Exception as e:
                logger.error(f"Failed to load Vosk model: {e}")
    
    async def recognize(self, audio_data: bytes, language: str = "en-US") -> Optional[str]:
        """Recognize speech using Vosk"""
        if not self.model:
            return None
        
        try:
            # Vosk expects 16kHz mono audio
            # Parse WAV header to get parameters
            audio_io = io.BytesIO(audio_data)
            with wave.open(audio_io, 'rb') as wf:
                sample_rate = wf.getframerate()
                audio_frames = wf.readframes(wf.getnframes())
            
            # Create recognizer
            rec = KaldiRecognizer(self.model, sample_rate)
            rec.SetWords(True)
            
            # Process audio
            rec.AcceptWaveform(audio_frames)
            result = json.loads(rec.FinalResult())
            
            return result.get("text", "")
            
        except Exception as e:
            logger.error(f"Vosk recognition error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.model is not None


class GoogleSpeechBackend(VoiceRecognitionBackend):
    """Google Speech Recognition - Good balance"""
    
    def __init__(self):
        self.recognizer = None
        if SR_AVAILABLE:
            self.recognizer = sr.Recognizer()
    
    async def recognize(self, audio_data: bytes, language: str = "en-US") -> Optional[str]:
        """Recognize speech using Google Speech Recognition"""
        if not self.recognizer:
            return None
        
        try:
            # Convert bytes to AudioData
            audio_io = io.BytesIO(audio_data)
            with sr.AudioFile(audio_io) as source:
                audio = self.recognizer.record(source)
            
            # Recognize with Google
            text = await asyncio.to_thread(
                self.recognizer.recognize_google,
                audio,
                language=language
            )
            return text
            
        except sr.UnknownValueError:
            logger.debug("Google Speech Recognition could not understand audio")
            return None
        except sr.RequestError as e:
            logger.error(f"Google Speech Recognition error: {e}")
            return None
        except Exception as e:
            logger.error(f"Recognition error: {e}")
            return None
    
    def is_available(self) -> bool:
        return self.recognizer is not None


class WebSpeechAPIBackend(VoiceRecognitionBackend):
    """Web Speech API - Browser-based (frontend only)"""
    
    def __init__(self):
        # This is a placeholder - Web Speech API runs in browser
        # This class exists for consistency and documentation
        pass
    
    async def recognize(self, audio_data: bytes, language: str = "en-US") -> Optional[str]:
        """Web Speech API runs in browser, not on server"""
        logger.warning("Web Speech API should be used in browser, not on server")
        return None
    
    def is_available(self) -> bool:
        return False  # Not available on server side


class VoiceRecognitionService:
    """
    Reusable Voice Recognition Service
    
    Supports multiple backends with automatic fallback:
    1. Whisper (best accuracy, costs money)
    2. Vosk (local, offline, fast)
    3. Google (good balance, requires internet)
    4. Web Speech API (browser-based)
    
    Example usage:
        service = VoiceRecognitionService()
        await service.initialize(whisper_api_key="sk-...")
        
        # Recognize audio
        text = await service.recognize(audio_bytes, language="nl-NL")
        
        # Or use callback for streaming
        await service.start_streaming_recognition(
            on_result=lambda text: print(f"You said: {text}")
        )
    """
    
    def __init__(self):
        self.backends: Dict[str, VoiceRecognitionBackend] = {}
        self.preferred_backend = "whisper"
        self.fallback_order = ["whisper", "vosk", "google"]
        
        # Callbacks for streaming recognition
        self.on_interim_result: Optional[Callable] = None
        self.on_final_result: Optional[Callable] = None
        self.on_error: Optional[Callable] = None
    
    async def initialize(
        self,
        whisper_api_key: Optional[str] = None,
        vosk_model_path: Optional[str] = None,
        preferred_backend: str = "whisper"
    ):
        """Initialize voice recognition service"""
        logger.info("Initializing Voice Recognition Service...")
        
        # Initialize backends
        self.backends["whisper"] = WhisperBackend(whisper_api_key)
        self.backends["vosk"] = VoskBackend(vosk_model_path)
        self.backends["google"] = GoogleSpeechBackend()
        self.backends["webspeech"] = WebSpeechAPIBackend()
        
        # Set preferred backend
        self.preferred_backend = preferred_backend
        
        # Log available backends
        available = [name for name, backend in self.backends.items() if backend.is_available()]
        logger.info(f"Available backends: {available}")
        
        if not available:
            logger.warning("No voice recognition backends available!")
        
        return self
    
    def get_available_backends(self) -> List[str]:
        """Get list of available backends"""
        return [name for name, backend in self.backends.items() if backend.is_available()]
    
    async def recognize(
        self,
        audio_data: bytes,
        language: str = "en-US",
        backend: Optional[str] = None
    ) -> Optional[str]:
        """
        Recognize speech from audio data
        
        Args:
            audio_data: Audio data in WAV format (bytes)
            language: Language code (e.g., "en-US", "nl-NL")
            backend: Specific backend to use (optional)
        
        Returns:
            Recognized text or None
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
            
            logger.info(f"Trying recognition with {backend_name}...")
            try:
                result = await backend_instance.recognize(audio_data, language)
                if result:
                    logger.info(f"Recognition successful with {backend_name}: {result[:50]}...")
                    return result
            except Exception as e:
                logger.error(f"Backend {backend_name} failed: {e}")
                continue
        
        logger.warning("All recognition backends failed")
        return None
    
    async def recognize_from_file(
        self,
        file_path: str,
        language: str = "en-US",
        backend: Optional[str] = None
    ) -> Optional[str]:
        """Recognize speech from audio file"""
        try:
            with open(file_path, "rb") as f:
                audio_data = f.read()
            return await self.recognize(audio_data, language, backend)
        except Exception as e:
            logger.error(f"Error reading audio file: {e}")
            return None
    
    def set_callbacks(
        self,
        on_interim_result: Optional[Callable] = None,
        on_final_result: Optional[Callable] = None,
        on_error: Optional[Callable] = None
    ):
        """Set callbacks for streaming recognition"""
        self.on_interim_result = on_interim_result
        self.on_final_result = on_final_result
        self.on_error = on_error
    
    async def recognize_stream(
        self,
        audio_stream,
        language: str = "en-US",
        backend: Optional[str] = None
    ):
        """
        Recognize speech from audio stream
        
        Args:
            audio_stream: Async generator yielding audio chunks
            language: Language code
            backend: Specific backend to use
        """
        # Accumulate audio chunks
        audio_buffer = b""
        
        async for chunk in audio_stream:
            audio_buffer += chunk
            
            # Process when we have enough data
            # This is a simple implementation - can be improved with VAD
            if len(audio_buffer) >= 32000:  # ~2 seconds at 16kHz
                result = await self.recognize(audio_buffer, language, backend)
                
                if result and self.on_interim_result:
                    await self.on_interim_result(result)
                
                # Reset buffer (or keep last chunk for continuity)
                audio_buffer = b""
    
    def get_backend_info(self) -> Dict[str, Any]:
        """Get information about available backends"""
        return {
            name: {
                "available": backend.is_available(),
                "type": type(backend).__name__,
                "description": backend.__doc__
            }
            for name, backend in self.backends.items()
        }


# Convenience function
async def create_voice_service(
    whisper_api_key: Optional[str] = None,
    vosk_model_path: Optional[str] = None,
    preferred: str = "whisper"
) -> VoiceRecognitionService:
    """Create and initialize voice recognition service"""
    service = VoiceRecognitionService()
    await service.initialize(whisper_api_key, vosk_model_path, preferred)
    return service
