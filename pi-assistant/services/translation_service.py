"""
Translation Service
Supports multiple translation providers with fallback
"""

import logging
import asyncio
from typing import Dict, Any, Optional
import json

logger = logging.getLogger(__name__)

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False

class TranslationService:
    """Handle translations between Dutch and English"""
    
    def __init__(self):
        self.providers = []
        self.cache = {}  # Simple in-memory cache
        
        # Initialize available providers
        self._init_providers()
    
    def _init_providers(self):
        """Initialize translation providers in order of preference"""
        # Add LibreTranslate (local/self-hosted option)
        self.providers.append(LibreTranslateProvider())
        
        # Add Ollama with multilingual model (offline option)
        self.providers.append(OllamaTranslateProvider())
        
        # Add simple dictionary lookup (always available)
        self.providers.append(DictionaryProvider())
    
    async def translate(
        self,
        text: str,
        from_lang: str,
        to_lang: str = None,
        include_pronunciation: bool = True
    ) -> Dict[str, Any]:
        """
        Translate text between languages
        
        Args:
            text: Text to translate
            from_lang: Source language ('dutch' or 'english')
            to_lang: Target language (auto-detect opposite if None)
            include_pronunciation: Include pronunciation guide
        
        Returns:
            Translation result with metadata
        """
        # Auto-detect target language
        if to_lang is None:
            to_lang = "english" if from_lang == "dutch" else "dutch"
        
        # Check cache
        cache_key = f"{from_lang}:{to_lang}:{text.lower()}"
        if cache_key in self.cache:
            logger.debug(f"Translation cache hit: {text}")
            return self.cache[cache_key]
        
        # Try each provider
        for provider in self.providers:
            try:
                result = await provider.translate(text, from_lang, to_lang)
                if result and result.get("success"):
                    # Add pronunciation if requested
                    if include_pronunciation and to_lang == "dutch":
                        result["pronunciation"] = self._get_pronunciation(result["translation"])
                    
                    # Cache result
                    self.cache[cache_key] = result
                    if len(self.cache) > 1000:  # Simple cache size limit
                        self.cache.pop(next(iter(self.cache)))
                    
                    return result
            except Exception as e:
                logger.warning(f"Provider {provider.__class__.__name__} failed: {e}")
                continue
        
        # All providers failed
        return {
            "success": False,
            "error": "All translation providers failed",
            "original": text,
            "translation": None
        }
    
    def _get_pronunciation(self, dutch_text: str) -> str:
        """Get pronunciation guide for Dutch text"""
        # Simple phonetic mapping for common sounds
        # In production, use IPA or proper TTS
        rules = {
            "ij": "ay",
            "ei": "ay",
            "ui": "ow",
            "ou": "ow",
            "aa": "ah",
            "ee": "ay",
            "oo": "oh",
            "uu": "ew",
            "ch": "kh",
            "g": "kh",
            "j": "y",
            "w": "v"
        }
        
        phonetic = dutch_text.lower()
        for dutch, english in rules.items():
            phonetic = phonetic.replace(dutch, english.upper())
        
        return phonetic


class LibreTranslateProvider:
    """LibreTranslate provider (free, self-hosted)"""
    
    def __init__(self, url: str = "http://localhost:5000"):
        self.url = url
        self.available = False
    
    async def translate(self, text: str, from_lang: str, to_lang: str) -> Dict[str, Any]:
        """Translate using LibreTranslate"""
        if not AIOHTTP_AVAILABLE:
            return {"success": False, "error": "aiohttp not available"}
        
        # Map our language codes to LibreTranslate codes
        lang_map = {"dutch": "nl", "english": "en"}
        source = lang_map.get(from_lang, from_lang)
        target = lang_map.get(to_lang, to_lang)
        
        try:
            async with aiohttp.ClientSession() as session:
                payload = {
                    "q": text,
                    "source": source,
                    "target": target,
                    "format": "text"
                }
                
                async with session.post(
                    f"{self.url}/translate",
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=5)
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        return {
                            "success": True,
                            "original": text,
                            "translation": data.get("translatedText", ""),
                            "provider": "LibreTranslate",
                            "from_language": from_lang,
                            "to_language": to_lang
                        }
        except Exception as e:
            logger.debug(f"LibreTranslate not available: {e}")
            return {"success": False, "error": str(e)}


class OllamaTranslateProvider:
    """Ollama-based translation (offline, uses local LLM)"""
    
    def __init__(self, url: str = "http://localhost:11434"):
        self.url = url
    
    async def translate(self, text: str, from_lang: str, to_lang: str) -> Dict[str, Any]:
        """Translate using Ollama with a multilingual model"""
        if not AIOHTTP_AVAILABLE:
            return {"success": False, "error": "aiohttp not available"}
        
        try:
            # Create translation prompt
            if to_lang == "dutch":
                prompt = f"Translate the following English text to Dutch. Only provide the translation, no explanation:\n\n{text}"
            else:
                prompt = f"Translate the following Dutch text to English. Only provide the translation, no explanation:\n\n{text}"
            
            async with aiohttp.ClientSession() as session:
                payload = {
                    "model": "llama3.2:3b",  # Fast, good for translation
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.3,  # Low temperature for consistent translations
                        "num_predict": 100
                    }
                }
                
                async with session.post(
                    f"{self.url}/api/generate",
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        translation = data.get("response", "").strip()
                        
                        return {
                            "success": True,
                            "original": text,
                            "translation": translation,
                            "provider": "Ollama",
                            "from_language": from_lang,
                            "to_language": to_lang
                        }
        except Exception as e:
            logger.debug(f"Ollama translation failed: {e}")
            return {"success": False, "error": str(e)}


class DictionaryProvider:
    """Basic dictionary lookup (always available fallback)"""
    
    def __init__(self):
        # Common translations dictionary
        self.dictionary = {
            # English to Dutch
            "hello": "hallo",
            "goodbye": "tot ziens",
            "please": "alsjeblieft",
            "thank you": "dank je wel",
            "yes": "ja",
            "no": "nee",
            "water": "water",
            "food": "eten",
            "house": "huis",
            "car": "auto",
            "cat": "kat",
            "dog": "hond",
            "book": "boek",
            "table": "tafel",
            "chair": "stoel",
            "good": "goed",
            "bad": "slecht",
            "big": "groot",
            "small": "klein",
            "hot": "heet",
            "cold": "koud",
            
            # Dutch to English (reverse mapping)
            "hallo": "hello",
            "tot ziens": "goodbye",
            "alsjeblieft": "please",
            "dank je wel": "thank you",
            "ja": "yes",
            "nee": "no",
            "eten": "food",
            "huis": "house",
            "auto": "car",
            "kat": "cat",
            "hond": "dog",
            "boek": "book",
            "tafel": "table",
            "stoel": "chair",
            "goed": "good",
            "slecht": "bad",
            "groot": "big",
            "klein": "small",
            "heet": "hot",
            "koud": "cold",
        }
    
    async def translate(self, text: str, from_lang: str, to_lang: str) -> Dict[str, Any]:
        """Simple dictionary lookup"""
        text_lower = text.lower().strip()
        
        if text_lower in self.dictionary:
            return {
                "success": True,
                "original": text,
                "translation": self.dictionary[text_lower],
                "provider": "Dictionary",
                "from_language": from_lang,
                "to_language": to_lang,
                "note": "Basic dictionary translation"
            }
        
        # Try word-by-word translation for phrases
        words = text_lower.split()
        if len(words) > 1:
            translated_words = [
                self.dictionary.get(word, word) for word in words
            ]
            return {
                "success": True,
                "original": text,
                "translation": " ".join(translated_words),
                "provider": "Dictionary",
                "from_language": from_lang,
                "to_language": to_lang,
                "note": "Word-by-word translation (may not be accurate)"
            }
        
        return {
            "success": False,
            "error": "Word not found in dictionary",
            "original": text,
            "translation": None
        }


# Global translation service instance
_translation_service = None

def get_translation_service() -> TranslationService:
    """Get or create translation service instance"""
    global _translation_service
    if _translation_service is None:
        _translation_service = TranslationService()
    return _translation_service
