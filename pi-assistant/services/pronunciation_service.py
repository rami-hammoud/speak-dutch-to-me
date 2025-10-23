"""
Pronunciation Scoring Service
Compare spoken audio to target pronunciation
"""

import logging
import asyncio
from typing import Dict, Any, Optional
import difflib
import re

logger = logging.getLogger(__name__)

try:
    import speech_recognition as sr
    import io
    import wave
    import base64
    SPEECH_RECOGNITION_AVAILABLE = True
except ImportError:
    SPEECH_RECOGNITION_AVAILABLE = False
    sr = None

class PronunciationScorer:
    """Score pronunciation attempts"""
    
    def __init__(self):
        self.recognizer = sr.Recognizer() if SPEECH_RECOGNITION_AVAILABLE else None
        
        # Pronunciation scoring thresholds
        self.excellent_threshold = 90
        self.good_threshold = 75
        self.needs_work_threshold = 60
    
    async def score_pronunciation(
        self,
        target_text: str,
        audio_data: str,
        audio_format: str = "wav",
        language: str = "nl-NL"  # Dutch
    ) -> Dict[str, Any]:
        """
        Score pronunciation by comparing speech-to-text output with target
        
        Args:
            target_text: Expected text to be spoken
            audio_data: Base64 encoded audio
            audio_format: Audio format (wav, mp3, etc.)
            language: Language code for recognition
        
        Returns:
            Scoring result with feedback
        """
        if not SPEECH_RECOGNITION_AVAILABLE:
            return {
                "success": False,
                "error": "Speech recognition not available. Install SpeechRecognition and pyaudio.",
                "score": 0.0
            }
        
        try:
            # Decode audio data
            if ',' in audio_data:
                audio_data = audio_data.split(',')[1]
            
            audio_bytes = base64.b64decode(audio_data)
            
            # Convert to AudioData format
            audio = sr.AudioData(audio_bytes, sample_rate=16000, sample_width=2)
            
            # Attempt recognition with multiple engines
            recognized_text = await self._recognize_speech(audio, language)
            
            if not recognized_text:
                return {
                    "success": False,
                    "error": "Could not recognize speech",
                    "score": 0.0,
                    "feedback": "Unable to understand the audio. Please try speaking more clearly."
                }
            
            # Calculate similarity score
            score = self._calculate_similarity(target_text, recognized_text)
            
            # Generate feedback
            feedback = self._generate_feedback(target_text, recognized_text, score)
            
            return {
                "success": True,
                "target": target_text,
                "recognized": recognized_text,
                "score": round(score, 1),
                "rating": self._get_rating(score),
                "feedback": feedback,
                "detailed_comparison": self._get_detailed_comparison(target_text, recognized_text)
            }
            
        except Exception as e:
            logger.error(f"Pronunciation scoring error: {e}")
            return {
                "success": False,
                "error": str(e),
                "score": 0.0
            }
    
    async def _recognize_speech(self, audio: Any, language: str) -> Optional[str]:
        """Attempt speech recognition with fallbacks"""
        # Try Google Speech Recognition (free, works well for Dutch)
        try:
            text = self.recognizer.recognize_google(audio, language=language)
            logger.info(f"Recognized (Google): {text}")
            return text.lower().strip()
        except sr.UnknownValueError:
            logger.warning("Google Speech Recognition could not understand audio")
        except sr.RequestError as e:
            logger.warning(f"Google Speech Recognition error: {e}")
        
        # Try Sphinx (offline, but less accurate)
        try:
            text = self.recognizer.recognize_sphinx(audio, language=language)
            logger.info(f"Recognized (Sphinx): {text}")
            return text.lower().strip()
        except Exception as e:
            logger.warning(f"Sphinx recognition failed: {e}")
        
        return None
    
    def _calculate_similarity(self, target: str, recognized: str) -> float:
        """Calculate similarity score between target and recognized text"""
        target_clean = self._clean_text(target)
        recognized_clean = self._clean_text(recognized)
        
        # Use sequence matcher for similarity
        similarity = difflib.SequenceMatcher(None, target_clean, recognized_clean).ratio()
        
        # Boost score if key words match
        target_words = set(target_clean.split())
        recognized_words = set(recognized_clean.split())
        
        if target_words and recognized_words:
            word_overlap = len(target_words & recognized_words) / len(target_words)
            # Weighted combination: 70% character similarity, 30% word overlap
            similarity = (similarity * 0.7) + (word_overlap * 0.3)
        
        return similarity * 100
    
    def _clean_text(self, text: str) -> str:
        """Clean and normalize text for comparison"""
        # Convert to lowercase
        text = text.lower()
        
        # Remove punctuation
        text = re.sub(r'[^\w\s]', '', text)
        
        # Remove extra whitespace
        text = ' '.join(text.split())
        
        return text
    
    def _get_rating(self, score: float) -> str:
        """Get rating category based on score"""
        if score >= self.excellent_threshold:
            return "excellent"
        elif score >= self.good_threshold:
            return "good"
        elif score >= self.needs_work_threshold:
            return "fair"
        else:
            return "needs_work"
    
    def _generate_feedback(self, target: str, recognized: str, score: float) -> str:
        """Generate helpful feedback based on pronunciation attempt"""
        rating = self._get_rating(score)
        
        feedback_templates = {
            "excellent": [
                "Excellent pronunciation! You sound like a native speaker!",
                "Perfect! Your Dutch pronunciation is spot on!",
                "Uitstekend! (Excellent!) Keep up the great work!"
            ],
            "good": [
                "Good job! Your pronunciation is quite clear.",
                "Well done! Just a few minor improvements needed.",
                "Goed gedaan! (Well done!) You're making great progress."
            ],
            "fair": [
                "Fair attempt. Focus on the sounds that differ from English.",
                "Keep practicing! Pay attention to the guttural 'g' sound.",
                "You're on the right track. Try speaking more slowly."
            ],
            "needs_work": [
                "Keep trying! Pronunciation takes practice.",
                "Listen carefully to native speakers and try to imitate.",
                "Don't worry, pronunciation is challenging. Keep practicing!"
            ]
        }
        
        import random
        base_feedback = random.choice(feedback_templates[rating])
        
        # Add specific feedback if there are differences
        if score < 100:
            target_words = set(self._clean_text(target).split())
            recognized_words = set(self._clean_text(recognized).split())
            
            missing_words = target_words - recognized_words
            if missing_words:
                base_feedback += f" Try to emphasize: {', '.join(missing_words)}."
        
        return base_feedback
    
    def _get_detailed_comparison(self, target: str, recognized: str) -> Dict[str, Any]:
        """Get detailed word-by-word comparison"""
        target_words = self._clean_text(target).split()
        recognized_words = self._clean_text(recognized).split()
        
        comparison = []
        max_len = max(len(target_words), len(recognized_words))
        
        for i in range(max_len):
            target_word = target_words[i] if i < len(target_words) else ""
            recognized_word = recognized_words[i] if i < len(recognized_words) else ""
            
            match = target_word == recognized_word
            similarity = difflib.SequenceMatcher(None, target_word, recognized_word).ratio()
            
            comparison.append({
                "position": i + 1,
                "target": target_word,
                "recognized": recognized_word,
                "match": match,
                "similarity": round(similarity * 100, 1)
            })
        
        return {
            "words": comparison,
            "total_words": len(target_words),
            "correct_words": sum(1 for c in comparison if c["match"])
        }


# Global pronunciation scorer instance
_pronunciation_scorer = None

def get_pronunciation_scorer() -> PronunciationScorer:
    """Get or create pronunciation scorer instance"""
    global _pronunciation_scorer
    if _pronunciation_scorer is None:
        _pronunciation_scorer = PronunciationScorer()
    return _pronunciation_scorer
