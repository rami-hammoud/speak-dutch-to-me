"""
Audio Manager for Pi Assistant
Handles microphone input, speaker output, and speech recognition
"""

import asyncio
import logging
import numpy as np
import io
import wave
from typing import Optional, Callable, Any
import threading
import time

try:
    import pyaudio
    import speech_recognition as sr
    import pyttsx3
    AUDIO_AVAILABLE = True
except ImportError:
    self.audio_available = False
    
from config import config

logger = logging.getLogger(__name__)

class AudioManager:
    """Manages audio input/output and speech recognition"""
    
    def __init__(self):
        self.is_recording = False
        self.recognizer = None
        self.microphone = None
        self.tts_engine = None
        self.pyaudio_instance = None
        self.stream = None
        self.audio_data = []
        
        # Audio settings
        self.sample_rate = 16000
        self.channels = 1
        self.chunk_size = 1024
        self.format = None
        
        self.audio_available = AUDIO_AVAILABLE
        if self.audio_available:
            self.format = pyaudio.paInt16
    
    async def initialize(self):
        if not self.audio_available:
        if not AUDIO_AVAILABLE:
            logger.warning("Audio libraries not available. Install pyaudio, SpeechRecognition, and pyttsx3")
            return
        
        try:
            # Initialize PyAudio
            self.pyaudio_instance = pyaudio.PyAudio()
            
            # Initialize speech recognition
            self.recognizer = sr.Recognizer()
            
            # Find microphone
            mic_list = sr.Microphone.list_microphone_names()
            logger.info(f"Available microphones: {mic_list}")
            
            # Use default microphone or specified device
            if config.AUDIO_INPUT_DEVICE:
                for i, name in enumerate(mic_list):
                    if config.AUDIO_INPUT_DEVICE.lower() in name.lower():
                        self.microphone = sr.Microphone(device_index=i)
                        break
            
            if not self.microphone:
                self.microphone = sr.Microphone()
            
            # Initialize text-to-speech
            self.tts_engine = pyttsx3.init()
            
            # Configure TTS
            voices = self.tts_engine.getProperty('voices')
            if voices:
                self.tts_engine.setProperty('voice', voices[0].id)
            self.tts_engine.setProperty('rate', 150)  # Speaking rate
            self.tts_engine.setProperty('volume', 0.8)
            
            # Adjust for ambient noise
            with self.microphone as source:
                logger.info("Adjusting for ambient noise...")
                self.recognizer.adjust_for_ambient_noise(source, duration=2)
            
            logger.info("Audio manager initialized successfully")
            
        except Exception as e:
            logger.error(f"Audio initialization error: {e}")
            AUDIO_AVAILABLE = False
    
    async def start_recording(self):
        if not self.audio_available or not self.microphone:
        if not AUDIO_AVAILABLE or not self.microphone:
            raise Exception("Audio not available")
        
        if self.is_recording:
            return
        
        try:
            self.is_recording = True
            self.audio_data = []
            
            # Start audio stream
            self.stream = self.pyaudio_instance.open(
                format=self.format,
                channels=self.channels,
                rate=self.sample_rate,
                input=True,
                frames_per_buffer=self.chunk_size,
                stream_callback=self._audio_callback
            )
            
            self.stream.start_stream()
            logger.info("Started audio recording")
            
        except Exception as e:
            self.is_recording = False
            logger.error(f"Failed to start recording: {e}")
            raise e
    
    async def stop_recording(self) -> Optional[str]:
        """Stop recording and return transcription"""
        if not self.is_recording or not self.stream:
            return None
        
        try:
            self.is_recording = False
            
            # Stop and close stream
            self.stream.stop_stream()
            self.stream.close()
            self.stream = None
            
            # Convert audio data to format for speech recognition
            if self.audio_data:
                audio_bytes = b''.join(self.audio_data)
                
                # Create WAV file in memory
                wav_io = io.BytesIO()
                with wave.open(wav_io, 'wb') as wav_file:
                    wav_file.setnchannels(self.channels)
                    wav_file.setsampwidth(self.pyaudio_instance.get_sample_size(self.format))
                    wav_file.setframerate(self.sample_rate)
                    wav_file.writeframes(audio_bytes)
                
                wav_io.seek(0)
                
                # Recognize speech
                with sr.AudioFile(wav_io) as source:
                    audio = self.recognizer.record(source)
                
                # Try different recognition methods
                transcription = await self._recognize_speech(audio)
                logger.info(f"Transcription: {transcription}")
                return transcription
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to stop recording: {e}")
            return None
    
    def _audio_callback(self, in_data, frame_count, time_info, status):
        """PyAudio callback for recording"""
        if self.is_recording:
            self.audio_data.append(in_data)
        return (in_data, pyaudio.paContinue)
    
    async def _recognize_speech(self, audio) -> Optional[str]:
        """Recognize speech from audio data"""
        try:
            # Try Google Speech Recognition (requires internet)
            try:
                text = self.recognizer.recognize_google(audio)
                return text
            except sr.RequestError:
                logger.warning("Google Speech Recognition unavailable")
            
            # Try offline recognition (if available)
            try:
                text = self.recognizer.recognize_sphinx(audio)
                return text
            except sr.RequestError:
                logger.warning("Sphinx recognition unavailable")
            
            # If we have OpenAI API, we could use Whisper API here
            # This would require implementing Whisper API integration
            
            return None
            
        except Exception as e:
            logger.error(f"Speech recognition error: {e}")
            return None
    
    async def speak(self, text: str, blocking: bool = False):
        if not self.audio_available or not self.tts_engine:
        if not AUDIO_AVAILABLE or not self.tts_engine:
            logger.warning("TTS not available")
            return
        
        try:
            if blocking:
                self.tts_engine.say(text)
                self.tts_engine.runAndWait()
            else:
                # Run TTS in thread to avoid blocking
                def speak_thread():
                    self.tts_engine.say(text)
                    self.tts_engine.runAndWait()
                
                thread = threading.Thread(target=speak_thread)
                thread.daemon = True
                thread.start()
                
        except Exception as e:
            logger.error(f"TTS error: {e}")
    
    async def play_audio_file(self, file_path: str):
        """Play an audio file"""
        try:
            if not AUDIO_AVAILABLE:
                # Fallback to system audio player
                import subprocess
                subprocess.run(['aplay', file_path], check=True)
                return
            
            # Load and play audio file with PyAudio
            with wave.open(file_path, 'rb') as wf:
                # Open output stream
                stream = self.pyaudio_instance.open(
                    format=self.pyaudio_instance.get_format_from_width(wf.getsampwidth()),
                    channels=wf.getnchannels(),
                    rate=wf.getframerate(),
                    output=True
                )
                
                # Play audio
                chunk = 1024
                data = wf.readframes(chunk)
                
                while data:
                    stream.write(data)
                    data = wf.readframes(chunk)
                
                stream.stop_stream()
                stream.close()
                
        except Exception as e:
            logger.error(f"Audio playback error: {e}")
    
    async def process_audio_chunk(self, audio_data: bytes) -> Optional[str]:
        """Process a chunk of audio data for real-time recognition"""
        # This would be used for WebSocket streaming audio
        # Implementation depends on the specific use case
        # Could accumulate chunks and process when silence is detected
        return None
    
    def get_audio_devices(self) -> dict:
        """Get list of available audio devices"""
        if not AUDIO_AVAILABLE or not self.pyaudio_instance:
            return {"input": [], "output": []}
        
        try:
            input_devices = []
            output_devices = []
            
            for i in range(self.pyaudio_instance.get_device_count()):
                info = self.pyaudio_instance.get_device_info_by_index(i)
                
                if info['maxInputChannels'] > 0:
                    input_devices.append({
                        'index': i,
                        'name': info['name'],
                        'channels': info['maxInputChannels']
                    })
                
                if info['maxOutputChannels'] > 0:
                    output_devices.append({
                        'index': i,
                        'name': info['name'],
                        'channels': info['maxOutputChannels']
                    })
            
            return {"input": input_devices, "output": output_devices}
            
        except Exception as e:
            logger.error(f"Error getting audio devices: {e}")
            return {"input": [], "output": []}
    
    async def cleanup(self):
        """Cleanup audio resources"""
        try:
            if self.is_recording:
                await self.stop_recording()
            
            if self.stream:
                self.stream.stop_stream()
                self.stream.close()
            
            if self.pyaudio_instance:
                self.pyaudio_instance.terminate()
            
            if self.tts_engine:
                self.tts_engine.stop()
            
            logger.info("Audio manager cleanup complete")
            
        except Exception as e:
            logger.error(f"Audio cleanup error: {e}")
