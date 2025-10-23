"""
MCP Module: Dutch Learning
Comprehensive Dutch language learning with vocabulary, grammar, pronunciation, and progress tracking
"""

import logging
import sqlite3
import json
import sys
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from pathlib import Path
from ..server import MCPTool

# Add parent directory to path for service imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Add imports for visual learning
import base64
import io

try:
    import cv2
    import numpy as np
    from PIL import Image
    VISION_AVAILABLE = True
except ImportError:
    VISION_AVAILABLE = False

# Import translation and pronunciation services
try:
    from services.translation_service import TranslationService
    from services.pronunciation_service import PronunciationScorer
    SERVICES_AVAILABLE = True
except ImportError:
    SERVICES_AVAILABLE = False
    TranslationService = None
    PronunciationScorer = None

logger = logging.getLogger(__name__)

class DutchLearningModule:
    """Dutch language learning capabilities"""
    
    def __init__(self):
        self.tools = []
        self.db_path = None
        self._initialized = False
        
        # Initialize services (will be properly set in initialize())
        self.translation_service = None
        self.pronunciation_scorer = None
        
        # Learning levels
        self.levels = {
            "A1": "Beginner",
            "A2": "Elementary",
            "B1": "Intermediate",
            "B2": "Upper Intermediate",
            "C1": "Advanced",
            "C2": "Mastery"
        }
        
        # Common Dutch categories
        self.categories = [
            "greetings", "numbers", "colors", "family", "food", 
            "travel", "shopping", "time", "weather", "body",
            "animals", "home", "work", "hobbies", "feelings"
        ]
        
        # Object-to-Dutch vocabulary mapping for visual learning
        self.object_vocabulary = {
            # Kitchen items
            "cup": {"dutch": "kop", "article": "de", "pronunciation": "kop"},
            "mug": {"dutch": "mok", "article": "de", "pronunciation": "mok"},
            "bottle": {"dutch": "fles", "article": "de", "pronunciation": "fles"},
            "glass": {"dutch": "glas", "article": "het", "pronunciation": "hlahs"},
            "spoon": {"dutch": "lepel", "article": "de", "pronunciation": "LAY-pul"},
            "fork": {"dutch": "vork", "article": "de", "pronunciation": "vork"},
            "knife": {"dutch": "mes", "article": "het", "pronunciation": "mes"},
            "plate": {"dutch": "bord", "article": "het", "pronunciation": "bort"},
            "bowl": {"dutch": "kom", "article": "de", "pronunciation": "kom"},
            
            # Food
            "apple": {"dutch": "appel", "article": "de", "pronunciation": "AH-pul"},
            "banana": {"dutch": "banaan", "article": "de", "pronunciation": "bah-NAHN"},
            "orange": {"dutch": "sinaasappel", "article": "de", "pronunciation": "see-NAHS-ah-pul"},
            "bread": {"dutch": "brood", "article": "het", "pronunciation": "broht"},
            "cheese": {"dutch": "kaas", "article": "de", "pronunciation": "kahs"},
            "milk": {"dutch": "melk", "article": "de", "pronunciation": "melk"},
            "coffee": {"dutch": "koffie", "article": "de", "pronunciation": "KOF-fee"},
            "tea": {"dutch": "thee", "article": "de", "pronunciation": "tay"},
            "water": {"dutch": "water", "article": "het", "pronunciation": "VAH-ter"},
            
            # Electronics
            "laptop": {"dutch": "laptop", "article": "de", "pronunciation": "LEP-top"},
            "phone": {"dutch": "telefoon", "article": "de", "pronunciation": "tay-lay-FOHN"},
            "keyboard": {"dutch": "toetsenbord", "article": "het", "pronunciation": "TOOT-sen-bort"},
            "mouse": {"dutch": "muis", "article": "de", "pronunciation": "mows"},
            "monitor": {"dutch": "beeldscherm", "article": "het", "pronunciation": "BAYLT-skherm"},
            
            # Furniture
            "chair": {"dutch": "stoel", "article": "de", "pronunciation": "stool"},
            "table": {"dutch": "tafel", "article": "de", "pronunciation": "TAH-fel"},
            "desk": {"dutch": "bureau", "article": "het", "pronunciation": "bew-ROH"},
            "bed": {"dutch": "bed", "article": "het", "pronunciation": "bet"},
            "sofa": {"dutch": "bank", "article": "de", "pronunciation": "bahnk"},
            
            # Common objects
            "book": {"dutch": "boek", "article": "het", "pronunciation": "book"},
            "pen": {"dutch": "pen", "article": "de", "pronunciation": "pen"},
            "paper": {"dutch": "papier", "article": "het", "pronunciation": "pah-PEER"},
            "bag": {"dutch": "tas", "article": "de", "pronunciation": "tas"},
            "clock": {"dutch": "klok", "article": "de", "pronunciation": "klok"},
            "door": {"dutch": "deur", "article": "de", "pronunciation": "dur"},
            "window": {"dutch": "raam", "article": "het", "pronunciation": "rahm"},
            
            # Animals
            "dog": {"dutch": "hond", "article": "de", "pronunciation": "hont"},
            "cat": {"dutch": "kat", "article": "de", "pronunciation": "kat"},
            "bird": {"dutch": "vogel", "article": "de", "pronunciation": "VOH-hel"},
            
            # Person detection
            "person": {"dutch": "persoon", "article": "de", "pronunciation": "per-SOHN"},
            "face": {"dutch": "gezicht", "article": "het", "pronunciation": "he-ZIKHT"},
        }
    
    async def initialize(self):
        """Initialize Dutch learning services"""
        logger.info("Initializing Dutch Learning Module...")
        
        # Setup database
        from config import config
        self.db_path = Path(config.DATA_DIR) / "dutch_learning.db"
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()
        
        # Initialize translation service
        if SERVICES_AVAILABLE and TranslationService:
            try:
                self.translation_service = TranslationService()
                logger.info("Translation service initialized")
            except Exception as e:
                logger.warning(f"Translation service initialization failed: {e}")
                self.translation_service = None
        else:
            logger.warning("Translation service not available - install aiohttp")
            self.translation_service = None
        
        # Initialize pronunciation scorer
        if SERVICES_AVAILABLE and PronunciationScorer:
            try:
                self.pronunciation_scorer = PronunciationScorer()
                logger.info("Pronunciation scorer initialized")
            except Exception as e:
                logger.warning(f"Pronunciation scorer initialization failed: {e}")
                self.pronunciation_scorer = None
        else:
            logger.warning("Pronunciation scorer not available - install SpeechRecognition")
            self.pronunciation_scorer = None
        
        # Register tools
        self.tools.extend([
            # Vocabulary tools
            MCPTool(
                name="dutch_vocabulary_search",
                description="Search Dutch vocabulary with translations and examples",
                input_schema={
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "category": {"type": "string"},
                        "level": {"type": "string", "enum": list(self.levels.keys())}
                    },
                    "required": ["query"]
                },
                handler=self._search_vocabulary
            ),
            MCPTool(
                name="dutch_vocabulary_add",
                description="Add a new word to personal vocabulary list",
                input_schema={
                    "type": "object",
                    "properties": {
                        "dutch_word": {"type": "string"},
                        "english_translation": {"type": "string"},
                        "category": {"type": "string"},
                        "level": {"type": "string"},
                        "example_sentence": {"type": "string"},
                        "pronunciation": {"type": "string"}
                    },
                    "required": ["dutch_word", "english_translation"]
                },
                handler=self._add_vocabulary
            ),
            MCPTool(
                name="dutch_vocabulary_review",
                description="Get vocabulary words for review (spaced repetition)",
                input_schema={
                    "type": "object",
                    "properties": {
                        "count": {"type": "integer", "default": 10},
                        "category": {"type": "string"},
                        "level": {"type": "string"}
                    }
                },
                handler=self._get_review_words
            ),
            
            # Grammar tools
            MCPTool(
                name="dutch_grammar_explain",
                description="Explain Dutch grammar rules",
                input_schema={
                    "type": "object",
                    "properties": {
                        "topic": {"type": "string"},
                        "level": {"type": "string"}
                    },
                    "required": ["topic"]
                },
                handler=self._explain_grammar
            ),
            MCPTool(
                name="dutch_grammar_exercise",
                description="Get grammar practice exercises",
                input_schema={
                    "type": "object",
                    "properties": {
                        "topic": {"type": "string"},
                        "difficulty": {"type": "string", "enum": ["easy", "medium", "hard"]},
                        "count": {"type": "integer", "default": 5}
                    },
                    "required": ["topic"]
                },
                handler=self._get_grammar_exercise
            ),
            
            # Translation tools
            MCPTool(
                name="dutch_translate",
                description="Translate between Dutch and English with context",
                input_schema={
                    "type": "object",
                    "properties": {
                        "text": {"type": "string"},
                        "from_language": {"type": "string", "enum": ["dutch", "english"]},
                        "include_pronunciation": {"type": "boolean", "default": True}
                    },
                    "required": ["text", "from_language"]
                },
                handler=self._translate
            ),
            
            # Pronunciation tools
            MCPTool(
                name="dutch_pronunciation_guide",
                description="Get pronunciation guide for Dutch words/phrases",
                input_schema={
                    "type": "object",
                    "properties": {
                        "text": {"type": "string"},
                        "include_audio": {"type": "boolean", "default": False}
                    },
                    "required": ["text"]
                },
                handler=self._get_pronunciation
            ),
            MCPTool(
                name="dutch_pronunciation_score",
                description="Score pronunciation attempt (requires audio input)",
                input_schema={
                    "type": "object",
                    "properties": {
                        "target_text": {"type": "string"},
                        "audio_data": {"type": "string"},
                        "audio_format": {"type": "string", "default": "wav"}
                    },
                    "required": ["target_text", "audio_data"]
                },
                handler=self._score_pronunciation
            ),
            
            # Practice tools
            MCPTool(
                name="dutch_conversation_practice",
                description="Start a Dutch conversation practice session",
                input_schema={
                    "type": "object",
                    "properties": {
                        "topic": {"type": "string"},
                        "level": {"type": "string"},
                        "mode": {"type": "string", "enum": ["chat", "voice"], "default": "chat"}
                    }
                },
                handler=self._start_conversation
            ),
            MCPTool(
                name="dutch_daily_challenge",
                description="Get daily learning challenge",
                input_schema={
                    "type": "object",
                    "properties": {
                        "level": {"type": "string"}
                    }
                },
                handler=self._get_daily_challenge
            ),
            
            # Progress tracking
            MCPTool(
                name="dutch_progress_stats",
                description="Get learning progress statistics",
                input_schema={
                    "type": "object",
                    "properties": {
                        "period": {"type": "string", "enum": ["week", "month", "all"], "default": "week"}
                    }
                },
                handler=self._get_progress_stats
            ),
            MCPTool(
                name="dutch_streak_info",
                description="Get current learning streak information",
                input_schema={
                    "type": "object",
                    "properties": {}
                },
                handler=self._get_streak_info
            ),
            
            # Visual learning
            MCPTool(
                name="dutch_camera_identify",
                description="Identify objects in camera view and teach Dutch words",
                input_schema={
                    "type": "object",
                    "properties": {
                        "image_data": {"type": "string"},
                        "include_examples": {"type": "boolean", "default": True}
                    },
                    "required": ["image_data"]
                },
                handler=self._camera_identify
            )
        ])
        
        self._initialized = True
        logger.info(f"Dutch Learning Module initialized with {len(self.tools)} tools")
    
    def _init_database(self):
        """Initialize SQLite database for Dutch learning"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Vocabulary table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS vocabulary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                dutch_word TEXT NOT NULL,
                english_translation TEXT NOT NULL,
                category TEXT,
                level TEXT,
                pronunciation TEXT,
                example_sentence TEXT,
                added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_reviewed TIMESTAMP,
                review_count INTEGER DEFAULT 0,
                mastery_score REAL DEFAULT 0.0
            )
        ''')
        
        # Practice sessions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS practice_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_type TEXT,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP,
                words_practiced INTEGER DEFAULT 0,
                correct_answers INTEGER DEFAULT 0,
                level TEXT
            )
        ''')
        
        # Progress tracking table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS daily_progress (
                date DATE PRIMARY KEY,
                words_learned INTEGER DEFAULT 0,
                words_reviewed INTEGER DEFAULT 0,
                time_spent_minutes INTEGER DEFAULT 0,
                exercises_completed INTEGER DEFAULT 0,
                streak_day INTEGER DEFAULT 0
            )
        ''')
        
        # Grammar topics table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS grammar_progress (
                topic TEXT PRIMARY KEY,
                mastery_level REAL DEFAULT 0.0,
                last_practiced TIMESTAMP,
                exercises_completed INTEGER DEFAULT 0
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info(f"Database initialized at {self.db_path}")
    
    def get_tools(self) -> List[MCPTool]:
        """Get all available tools"""
        return self.tools
    
    # Tool implementations
    
    async def _search_vocabulary(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Search vocabulary database"""
        query = params.get("query", "").lower()
        category = params.get("category")
        level = params.get("level")
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        sql = "SELECT * FROM vocabulary WHERE (dutch_word LIKE ? OR english_translation LIKE ?)"
        args = [f"%{query}%", f"%{query}%"]
        
        if category:
            sql += " AND category = ?"
            args.append(category)
        if level:
            sql += " AND level = ?"
            args.append(level)
        
        sql += " LIMIT 20"
        
        cursor.execute(sql, args)
        results = cursor.fetchall()
        conn.close()
        
        return {
            "success": True,
            "results": [
                {
                    "dutch": row[1],
                    "english": row[2],
                    "category": row[3],
                    "level": row[4],
                    "pronunciation": row[5],
                    "example": row[6],
                    "mastery": row[10]
                }
                for row in results
            ]
        }
    
    async def _add_vocabulary(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Add word to vocabulary"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO vocabulary 
            (dutch_word, english_translation, category, level, pronunciation, example_sentence)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            params.get("dutch_word"),
            params.get("english_translation"),
            params.get("category", "general"),
            params.get("level", "A1"),
            params.get("pronunciation", ""),
            params.get("example_sentence", "")
        ))
        
        word_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return {
            "success": True,
            "word_id": word_id,
            "message": f"Added '{params.get('dutch_word')}' to vocabulary"
        }
    
    async def _get_review_words(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get words for spaced repetition review"""
        count = params.get("count", 10)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Prioritize words that haven't been reviewed or have low mastery
        cursor.execute('''
            SELECT dutch_word, english_translation, pronunciation, example_sentence, mastery_score
            FROM vocabulary
            WHERE mastery_score < 0.8
            ORDER BY 
                CASE WHEN last_reviewed IS NULL THEN 0 ELSE 1 END,
                last_reviewed ASC,
                mastery_score ASC
            LIMIT ?
        ''', (count,))
        
        words = cursor.fetchall()
        conn.close()
        
        return {
            "success": True,
            "words": [
                {
                    "dutch": w[0],
                    "english": w[1],
                    "pronunciation": w[2],
                    "example": w[3],
                    "current_mastery": w[4]
                }
                for w in words
            ],
            "count": len(words)
        }
    
    async def _explain_grammar(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Explain Dutch grammar topic"""
        topic = params.get("topic", "").lower()
        
        # Common grammar explanations
        grammar_rules = {
            "word order": {
                "explanation": "Dutch has a specific word order (SOV in subordinate clauses, V2 in main clauses)",
                "examples": [
                    "Ik eet een appel (I eat an apple)",
                    "omdat ik een appel eet (because I eat an apple)"
                ],
                "rules": [
                    "Main clause: Subject-Verb-Object",
                    "With 'omdat', 'dat': verb goes to end",
                    "Questions: Verb-Subject-Object"
                ]
            },
            "articles": {
                "explanation": "Dutch has two articles: 'de' (common gender) and 'het' (neuter)",
                "examples": [
                    "de man (the man)",
                    "het huis (the house)",
                    "de vrouw (the woman)"
                ],
                "rules": [
                    "About 2/3 of nouns use 'de'",
                    "Plural always uses 'de'",
                    "Diminutives always use 'het'"
                ]
            },
            "verb conjugation": {
                "explanation": "Dutch verbs conjugate based on person and tense",
                "examples": [
                    "ik loop (I walk)",
                    "jij loopt (you walk)",
                    "hij/zij loopt (he/she walks)"
                ],
                "rules": [
                    "Remove -en to get stem",
                    "Add -t for jij/hij/zij",
                    "No ending for ik"
                ]
            }
        }
        
        result = grammar_rules.get(topic, {
            "explanation": f"Grammar topic '{topic}' explanation coming soon",
            "examples": [],
            "rules": []
        })
        
        return {
            "success": True,
            "topic": topic,
            **result
        }
    
    async def _get_grammar_exercise(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate grammar exercises"""
        topic = params.get("topic")
        difficulty = params.get("difficulty", "easy")
        count = params.get("count", 5)
        
        # Sample exercises (would be generated dynamically)
        exercises = [
            {
                "question": "Fill in the correct article: ___ huis is groot",
                "options": ["de", "het", "een"],
                "correct": "het",
                "explanation": "Huis is neuter, so it takes 'het'"
            },
            {
                "question": "Conjugate 'lopen' for 'jij': jij ___",
                "options": ["loop", "loopt", "lopen"],
                "correct": "loopt",
                "explanation": "Add -t for jij"
            }
        ]
        
        return {
            "success": True,
            "topic": topic,
            "difficulty": difficulty,
            "exercises": exercises[:count]
        }
    
    async def _translate(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Translate text"""
        text = params.get("text")
        from_lang = params.get("from_language")
        include_pronunciation = params.get("include_pronunciation", True)
        
        if not text:
            return {
                "success": False,
                "error": "No text provided"
            }
        
        # Use translation service if available
        if self.translation_service:
            try:
                result = await self.translation_service.translate(
                    text=text,
                    from_lang=from_lang,
                    include_pronunciation=include_pronunciation
                )
                return result
            except Exception as e:
                logger.error(f"Translation error: {e}")
                return {
                    "success": False,
                    "error": str(e),
                    "original": text
                }
        
        # Fallback to placeholder
        return {
            "success": False,
            "original": text,
            "translation": "[Translation service not configured]",
            "error": "Translation service not available"
        }
    
    async def _get_pronunciation(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get pronunciation guide"""
        text = params.get("text")
        
        # Simple phonetic mapping (would use proper IPA)
        return {
            "success": True,
            "text": text,
            "phonetic": "[phonetic transcription]",
            "audio_url": None if not params.get("include_audio") else "/audio/pronunciation.mp3",
            "tips": [
                "Dutch 'g' is guttural, like clearing throat",
                "Dutch 'ui' sound doesn't exist in English",
                "Rolling 'r' is common in Dutch"
            ]
        }
    
    async def _score_pronunciation(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Score pronunciation attempt"""
        target_text = params.get("target_text")
        audio_data = params.get("audio_data")
        audio_format = params.get("audio_format", "wav")
        
        if not target_text or not audio_data:
            return {
                "success": False,
                "error": "Missing target_text or audio_data"
            }
        
        # Use pronunciation scorer if available
        if self.pronunciation_scorer:
            try:
                result = await self.pronunciation_scorer.score_pronunciation(
                    target_text=target_text,
                    audio_data=audio_data,
                    audio_format=audio_format,
                    language="nl-NL"
                )
                
                # Log progress if scoring was successful
                if result.get("success") and result.get("score", 0) >= 70:
                    await self._log_practice_session("pronunciation", 1, target_text)
                
                return result
            except Exception as e:
                logger.error(f"Pronunciation scoring error: {e}")
                return {
                    "success": False,
                    "error": str(e)
                }
        
        # Fallback
        return {
            "success": False,
            "error": "Pronunciation scoring service not available",
            "message": "Install speech_recognition library for pronunciation scoring"
        }
    
    async def _start_conversation(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Start conversation practice"""
        topic = params.get("topic", "daily life")
        level = params.get("level", "A1")
        
        prompts = {
            "A1": "Hallo! Hoe heet je? (Hello! What's your name?)",
            "A2": "Wat doe je graag in je vrije tijd? (What do you like to do in your free time?)",
            "B1": "Kun je me vertellen over je laatste vakantie? (Can you tell me about your last vacation?)"
        }
        
        return {
            "success": True,
            "session_id": "conv_123",
            "topic": topic,
            "level": level,
            "first_prompt": prompts.get(level, prompts["A1"]),
            "mode": params.get("mode", "chat")
        }
    
    async def _get_daily_challenge(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get daily challenge"""
        level = params.get("level", "A1")
        
        return {
            "success": True,
            "challenge": {
                "date": datetime.now().strftime("%Y-%m-%d"),
                "type": "vocabulary",
                "title": "Learn 10 new words about food",
                "words": ["brood", "kaas", "appel", "water", "koffie"],
                "goal": "Learn and review 10 words",
                "reward_points": 50
            }
        }
    
    async def _get_progress_stats(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get learning progress statistics"""
        period = params.get("period", "week")
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        if period == "week":
            days_back = 7
        elif period == "month":
            days_back = 30
        else:
            days_back = 365
        
        cursor.execute('''
            SELECT 
                SUM(words_learned),
                SUM(words_reviewed),
                SUM(time_spent_minutes),
                SUM(exercises_completed)
            FROM daily_progress
            WHERE date >= date('now', '-' || ? || ' days')
        ''', (days_back,))
        
        stats = cursor.fetchone()
        
        cursor.execute("SELECT COUNT(*) FROM vocabulary")
        total_words = cursor.fetchone()[0]
        
        cursor.execute("SELECT AVG(mastery_score) FROM vocabulary")
        avg_mastery = cursor.fetchone()[0] or 0.0
        
        conn.close()
        
        return {
            "success": True,
            "period": period,
            "stats": {
                "words_learned": stats[0] or 0,
                "words_reviewed": stats[1] or 0,
                "time_spent_minutes": stats[2] or 0,
                "exercises_completed": stats[3] or 0,
                "total_vocabulary": total_words,
                "average_mastery": round(avg_mastery * 100, 1)
            }
        }
    
    async def _get_streak_info(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get learning streak information"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT MAX(streak_day) FROM daily_progress
            WHERE date >= date('now', '-30 days')
        ''')
        current_streak = cursor.fetchone()[0] or 0
        
        conn.close()
        
        return {
            "success": True,
            "current_streak": current_streak,
            "message": f"You've been learning for {current_streak} days in a row!" if current_streak > 0 else "Start your streak today!",
            "next_milestone": 7 if current_streak < 7 else 30
        }
    
    async def _camera_identify(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Identify objects in camera and teach Dutch"""
        if not VISION_AVAILABLE:
            return {
                "success": False,
                "error": "Computer vision libraries not available. Install opencv-python and pillow.",
                "objects": []
            }
        
        image_data = params.get("image_data")
        if not image_data:
            return {
                "success": False,
                "error": "No image data provided",
                "objects": []
            }
        
        try:
            # Decode base64 image
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            img_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return {
                    "success": False,
                    "error": "Failed to decode image",
                    "objects": []
                }
            
            # Detect objects using a simple classifier
            # In production, you would use YOLO, MobileNet, or similar
            detected_objects = await self._detect_objects_simple(img)
            
            # Map detected objects to Dutch vocabulary
            dutch_vocab = []
            for obj in detected_objects:
                obj_name = obj.get("name", "").lower()
                if obj_name in self.object_vocabulary:
                    vocab = self.object_vocabulary[obj_name]
                    dutch_vocab.append({
                        "english": obj_name,
                        "dutch": vocab["dutch"],
                        "article": vocab["article"],
                        "pronunciation": vocab["pronunciation"],
                        "full_term": f"{vocab['article']} {vocab['dutch']}",
                        "example": self._generate_example_sentence(vocab["dutch"], vocab["article"]),
                        "confidence": obj.get("confidence", 0.0)
                    })
            
            # Add to user's vocabulary if requested
            if params.get("save_to_vocabulary", False):
                for vocab in dutch_vocab:
                    try:
                        await self._add_vocabulary({
                            "dutch_word": vocab["dutch"],
                            "english_translation": vocab["english"],
                            "category": "visual_learning",
                            "level": "A1",
                            "example_sentence": vocab["example"],
                            "pronunciation": vocab["pronunciation"]
                        })
                    except Exception as e:
                        logger.warning(f"Failed to save vocabulary: {e}")
            
            return {
                "success": True,
                "objects": dutch_vocab,
                "count": len(dutch_vocab),
                "message": f"Identified {len(dutch_vocab)} object(s) in Dutch!"
            }
            
        except Exception as e:
            logger.error(f"Error in camera identification: {e}")
            return {
                "success": False,
                "error": str(e),
                "objects": []
            }
    
    async def _detect_objects_simple(self, img) -> List[Dict[str, Any]]:
        """Simple object detection (placeholder for proper ML model)"""
        # This is a placeholder. In production, use:
        # - YOLO for general object detection
        # - MobileNet SSD for edge devices
        # - TensorFlow Lite for Raspberry Pi
        
        detected = []
        
        # For now, use basic color/shape detection as a demo
        # Detect blue objects (could be a cup, bottle, etc.)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        
        # Blue color range
        lower_blue = np.array([100, 50, 50])
        upper_blue = np.array([130, 255, 255])
        mask_blue = cv2.inRange(hsv, lower_blue, upper_blue)
        
        # Red color range
        lower_red1 = np.array([0, 50, 50])
        upper_red1 = np.array([10, 255, 255])
        lower_red2 = np.array([170, 50, 50])
        upper_red2 = np.array([180, 255, 255])
        mask_red = cv2.inRange(hsv, lower_red1, upper_red1) | cv2.inRange(hsv, lower_red2, upper_red2)
        
        # Find contours
        contours_blue, _ = cv2.findContours(mask_blue, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        contours_red, _ = cv2.findContours(mask_red, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Process blue objects
        for contour in contours_blue:
            area = cv2.contourArea(contour)
            if area > 500:  # Filter small noise
                detected.append({
                    "name": "cup",  # Demo: assume blue objects are cups
                    "confidence": 0.7,
                    "color": "blue"
                })
                break  # Just detect one for demo
        
        # Process red objects
        for contour in contours_red:
            area = cv2.contourArea(contour)
            if area > 500:
                detected.append({
                    "name": "apple",  # Demo: assume red objects are apples
                    "confidence": 0.7,
                    "color": "red"
                })
                break
        
        # If no objects detected by color, return a default common object
        if not detected:
            detected.append({
                "name": "book",
                "confidence": 0.5,
                "note": "Demo mode - showing example vocabulary"
            })
        
        return detected
    
    def _generate_example_sentence(self, dutch_word: str, article: str) -> str:
        """Generate an example sentence for a Dutch word"""
        sentences = {
            "appel": "Ik eet een appel (I eat an apple)",
            "boek": "Het boek is interessant (The book is interesting)",
            "kop": "De kop is leeg (The cup is empty)",
            "stoel": "De stoel is comfortabel (The chair is comfortable)",
            "hond": "De hond speelt buiten (The dog plays outside)",
        }
        
        if dutch_word in sentences:
            return sentences[dutch_word]
        
        # Generate generic sentence
        if article == "de":
            return f"De {dutch_word} is mooi (The {dutch_word} is beautiful)"
        else:
            return f"Het {dutch_word} is goed (The {dutch_word} is good)"
    
    async def _log_practice_session(self, session_type: str, words_practiced: int, notes: str = ""):
        """Log a practice session"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO practice_sessions (session_type, words_practiced)
                VALUES (?, ?)
            ''', (session_type, words_practiced))
            
            conn.commit()
            conn.close()
            logger.debug(f"Logged {session_type} session with {words_practiced} words")
        except Exception as e:
            logger.error(f"Failed to log practice session: {e}")
    
    async def cleanup(self):
        """Cleanup resources"""
        self._initialized = False
        logger.info("Dutch Learning Module cleaned up")
