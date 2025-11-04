"""
Voice Command Router for MCP Agents
AI-powered voice command system that routes requests to appropriate MCP agents
"""

import asyncio
import logging
import json
import re
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class CommandIntent(Enum):
    """Possible command intents"""
    SHOPPING = "shopping"
    HOME_AUTOMATION = "home_automation"
    DUTCH_LEARNING = "dutch_learning"
    SYSTEM_CONTROL = "system_control"
    CAMERA = "camera"
    INFORMATION = "information"
    UNKNOWN = "unknown"


@dataclass
class VoiceCommand:
    """Parsed voice command"""
    raw_text: str
    intent: CommandIntent
    confidence: float
    entities: Dict[str, Any]
    agent: Optional[str] = None
    action: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None


@dataclass
class CommandResponse:
    """Response from command execution"""
    success: bool
    message: str
    data: Optional[Dict[str, Any]] = None
    speak: bool = True  # Whether to speak the response


class VoiceCommandRouter:
    """
    AI-powered voice command router for MCP agents
    
    Routes natural language commands to appropriate MCP agents and actions.
    Uses pattern matching and AI for intent recognition.
    
    Example usage:
        router = VoiceCommandRouter()
        await router.initialize(ai_service, mcp_server)
        
        # Process voice command
        command = await router.parse_command("Find me a keyboard under $50")
        response = await router.execute_command(command)
        
        # Response contains: success, message, and optional data
        if response.speak:
            await tts.speak(response.message)
    """
    
    def __init__(self):
        self.ai_service = None
        self.mcp_server = None
        self.command_patterns = {}
        self.agents = {}
        self.command_history = []
        self.context = {}  # Conversation context
        
        # Initialize command patterns
        self._init_patterns()
    
    def _init_patterns(self):
        """Initialize command patterns for intent recognition"""
        
        # Shopping patterns
        self.command_patterns[CommandIntent.SHOPPING] = [
            r"(?:find|search|look for|show me|get me)\s+(?:a|an|some)?\s*(.+?)(?:\s+(?:under|for|around|about)\s+\$?(\d+))?",
            r"(?:buy|purchase|order)\s+(.+)",
            r"(?:what|show)\s+(?:are|is)?\s*(?:the)?\s*(?:price|cost|prices)\s+(?:of|for)\s+(.+)",
            r"(?:compare|check)\s+prices?\s+(?:for|of)\s+(.+)",
            r"(?:add|put)\s+(.+)\s+(?:to|in)\s+(?:my\s+)?cart",
            r"(?:show|check|view)\s+(?:my\s+)?(?:cart|basket|shopping cart)",
        ]
        
        # Home automation patterns (for future)
        self.command_patterns[CommandIntent.HOME_AUTOMATION] = [
            r"(?:turn|switch)\s+(on|off)\s+(?:the\s+)?(.+)",
            r"(?:set|change)\s+(?:the\s+)?(.+?)\s+to\s+(.+)",
            r"(?:dim|brighten)\s+(?:the\s+)?(.+)",
            r"(?:what(?:'s| is))\s+(?:the\s+)?(.+?)\s+(?:temperature|status)",
            r"(?:lock|unlock)\s+(?:the\s+)?(.+)",
        ]
        
        # Dutch learning patterns
        self.command_patterns[CommandIntent.DUTCH_LEARNING] = [
            r"(?:how do you say|what is|translate)\s+(.+?)\s+(?:in dutch|to dutch)",
            r"(?:teach me|show me|tell me)\s+(?:the\s+)?dutch\s+(?:word|phrase)\s+for\s+(.+)",
            r"(?:practice|learn|study)\s+(.+)",
            r"(?:save|add)\s+(?:the\s+)?(?:word|vocabulary)\s+(.+)",
            r"(?:show|view|list)\s+(?:my\s+)?vocabulary",
        ]
        
        # Personal assistant / Calendar patterns
        self.command_patterns[CommandIntent.INFORMATION] = [
            r"(?:what(?:'s| is)|show|list|tell me)\s+(?:on\s+)?(?:my\s+)?(?:calendar|schedule|events?)\s*(?:today|tomorrow|this week)?",
            r"(?:do i have|what(?:'s| is)|any)\s+(?:any\s+)?(?:meetings?|events?|appointments?)\s+(?:today|tomorrow|this week)",
            r"(?:add|create|schedule|make)\s+(?:a\s+)?(?:meeting|event|appointment)\s+(.+)",
            r"(?:schedule|set up|create)\s+(.+?)\s+(?:for|on|at)\s+(.+)",
            r"(?:cancel|delete|remove)\s+(?:my\s+)?(?:meeting|event|appointment)\s+(.+)",
            r"(?:when is|what time is)\s+(?:my\s+)?(.+)",
        ]
        
        # Camera patterns
        self.command_patterns[CommandIntent.CAMERA] = [
            r"(?:take|capture|snap)\s+(?:a\s+)?(?:picture|photo|image)",
            r"(?:show|display)\s+(?:the\s+)?camera",
            r"(?:what|identify|recognize)\s+(?:is\s+)?(?:this|that)",
        ]
        
        # System control patterns
        self.command_patterns[CommandIntent.SYSTEM_CONTROL] = [
            r"(?:what(?:'s| is))\s+(?:the\s+)?(?:time|date)",
            r"(?:what(?:'s| is))\s+(?:the\s+)?weather",
            r"(?:system|assistant)\s+(status|info|information)",
            r"(?:stop|quit|exit|goodbye|bye)",
        ]
    
    async def initialize(self, ai_service, mcp_server):
        """Initialize with AI service and MCP server"""
        self.ai_service = ai_service
        self.mcp_server = mcp_server
        logger.info("Voice command router initialized")
    
    async def parse_command(self, text: str, use_ai: bool = True) -> VoiceCommand:
        """
        Parse voice command and determine intent
        
        Args:
            text: Raw voice command text
            use_ai: Whether to use AI for parsing (fallback to patterns)
        
        Returns:
            VoiceCommand with intent and extracted entities
        """
        text = text.strip().lower()
        
        # First try pattern matching (fast)
        intent, entities, confidence = self._pattern_match(text)
        
        # If low confidence and AI available, use AI
        if confidence < 0.7 and use_ai and self.ai_service:
            ai_result = await self._ai_parse(text)
            if ai_result and ai_result.get('confidence', 0) > confidence:
                intent = CommandIntent(ai_result['intent'])
                entities = ai_result.get('entities', {})
                confidence = ai_result['confidence']
        
        command = VoiceCommand(
            raw_text=text,
            intent=intent,
            confidence=confidence,
            entities=entities
        )
        
        # Map to agent and action
        self._map_to_agent(command)
        
        logger.info(f"Parsed command: intent={command.intent.value}, confidence={confidence:.2f}")
        return command
    
    def _pattern_match(self, text: str) -> tuple:
        """Match text against patterns"""
        best_intent = CommandIntent.UNKNOWN
        best_entities = {}
        best_confidence = 0.0
        
        for intent, patterns in self.command_patterns.items():
            for pattern in patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    confidence = 0.8  # Pattern match confidence
                    entities = {f"group_{i}": g for i, g in enumerate(match.groups()) if g}
                    
                    if confidence > best_confidence:
                        best_confidence = confidence
                        best_intent = intent
                        best_entities = entities
        
        return best_intent, best_entities, best_confidence
    
    async def _ai_parse(self, text: str) -> Optional[Dict]:
        """Use AI to parse command intent"""
        try:
            # Create prompt for AI
            prompt = f"""Parse this voice command and extract the intent and entities.

Command: "{text}"

Available intents:
- shopping: Finding/buying products, price checking, cart management
- home_automation: Controlling smart home devices, lights, temperature
- dutch_learning: Language learning, vocabulary, pronunciation
- camera: Taking photos, identifying objects
- system_control: System status, time, weather
- information: General questions

Respond in JSON format:
{{
    "intent": "shopping",
    "confidence": 0.9,
    "entities": {{
        "product": "keyboard",
        "price_limit": 50
    }},
    "action": "search_product"
}}"""

            from ai_service import Message
            messages = [Message(role="user", content=prompt)]
            
            response = await self.ai_service.chat(messages)
            result = json.loads(response.content)
            return result
            
        except Exception as e:
            logger.error(f"AI parsing error: {e}")
            return None
    
    def _map_to_agent(self, command: VoiceCommand):
        """Map command to MCP agent and action"""
        
        # Shopping commands
        if command.intent == CommandIntent.SHOPPING:
            command.agent = "ecommerce"
            
            # Determine action from entities
            if "group_0" in command.entities:
                product = command.entities["group_0"]
                price = command.entities.get("group_1")
                
                if "compare" in command.raw_text or "price" in command.raw_text:
                    command.action = "price_compare"
                    command.parameters = {"product_name": product}
                elif "cart" in command.raw_text:
                    command.action = "view_cart" if "show" in command.raw_text or "view" in command.raw_text else "add_to_cart"
                    command.parameters = {"product": product}
                else:
                    command.action = "product_search"
                    command.parameters = {
                        "query": product,
                        "max_price": float(price) if price else None
                    }
        
        # Dutch learning commands
        elif command.intent == CommandIntent.DUTCH_LEARNING:
            command.agent = "dutch_learning"
            
            if "translate" in command.raw_text or "how do you say" in command.raw_text:
                command.action = "dutch_vocabulary_search"
                command.parameters = {"query": command.entities.get("group_0", "")}
            elif "vocabulary" in command.raw_text:
                command.action = "dutch_vocabulary_review"
                command.parameters = {"count": 10}
        
        # Personal assistant / Calendar commands
        elif command.intent == CommandIntent.INFORMATION:
            command.agent = "personal_assistant"
            
            if "calendar" in command.raw_text or "schedule" in command.raw_text or "events" in command.raw_text or "meetings" in command.raw_text:
                if "add" in command.raw_text or "create" in command.raw_text or "schedule" in command.raw_text:
                    command.action = "calendar_create_event"
                    # Extract event details from groups
                    event_details = command.entities.get("group_0", "")
                    time_details = command.entities.get("group_1", "tomorrow at 2pm")
                    command.parameters = {
                        "title": event_details,
                        "start_time": time_details,
                        "duration_minutes": 60
                    }
                else:
                    command.action = "calendar_list_events"
                    # Determine timeframe
                    if "today" in command.raw_text:
                        timeframe = "today"
                    elif "tomorrow" in command.raw_text:
                        timeframe = "tomorrow"
                    elif "week" in command.raw_text:
                        timeframe = "week"
                    else:
                        timeframe = "today"
                    command.parameters = {"timeframe": timeframe}
        
        # Camera commands
        elif command.intent == CommandIntent.CAMERA:
            command.agent = "personal_assistant"
            command.action = "camera_capture"
            command.parameters = {}
        
        # Home automation (future)
        elif command.intent == CommandIntent.HOME_AUTOMATION:
            command.agent = "home_automation"  # Future agent
            command.action = "control_device"
            # Extract device and action from entities
            command.parameters = {
                "device": command.entities.get("group_1", ""),
                "state": command.entities.get("group_0", "")
            }
    
    async def execute_command(self, command: VoiceCommand) -> CommandResponse:
        """
        Execute command via appropriate MCP agent
        
        Args:
            command: Parsed voice command
        
        Returns:
            CommandResponse with result and message
        """
        try:
            # Check if agent is available
            if not command.agent:
                return CommandResponse(
                    success=False,
                    message=f"I'm not sure how to handle that command. Can you rephrase?",
                    speak=True
                )
            
            # Execute via MCP server
            logger.info(f"Executing: {command.agent}.{command.action} with params {command.parameters}")
            
            result = await self.mcp_server.execute_tool(
                command.action,
                command.parameters or {}
            )
            
            # Format response
            response_message = self._format_response(command, result)
            
            # Store in history
            self.command_history.append({
                "command": command.raw_text,
                "intent": command.intent.value,
                "result": result
            })
            
            return CommandResponse(
                success=True,
                message=response_message,
                data=result,
                speak=True
            )
            
        except Exception as e:
            logger.error(f"Command execution error: {e}")
            return CommandResponse(
                success=False,
                message=f"Sorry, I encountered an error: {str(e)}",
                speak=True
            )
    
    def _format_response(self, command: VoiceCommand, result: Dict) -> str:
        """Format MCP result into natural language response"""
        
        # Shopping responses
        if command.intent == CommandIntent.SHOPPING:
            if command.action == "product_search":
                products = result.get("products", [])
                if products:
                    product = products[0]
                    return f"I found {product['name']} for ${product['price']}. Would you like to hear more options?"
                else:
                    return "I couldn't find any products matching that description."
            
            elif command.action == "price_compare":
                comparisons = result.get("comparisons", [])
                if comparisons:
                    best = result.get("best_deal", comparisons[0])
                    return f"The best price is ${best['total_price']} on {best['platform']}."
                else:
                    return "I couldn't compare prices for that product."
            
            elif command.action == "view_cart":
                items = result.get("items", [])
                if items:
                    return f"You have {len(items)} items in your cart."
                else:
                    return "Your cart is empty."
        
        # Dutch learning responses
        elif command.intent == CommandIntent.DUTCH_LEARNING:
            if command.action == "dutch_vocabulary_search":
                results = result.get("results", [])
                if results:
                    word = results[0]
                    return f"In Dutch, that's '{word['dutch']}'. {word.get('article', '')} {word['dutch']}."
                else:
                    return "I couldn't find that in the vocabulary."
        
        # Personal assistant / Calendar responses
        elif command.intent == CommandIntent.INFORMATION:
            if command.action == "calendar_list_events":
                events = result.get("events", [])
                timeframe = result.get("timeframe", "")
                if events:
                    event_list = ", ".join([f"{e['summary']} at {e['start']}" for e in events[:3]])
                    if len(events) > 3:
                        return f"You have {len(events)} events {timeframe}. Here are the first few: {event_list}"
                    else:
                        return f"You have {len(events)} event(s) {timeframe}: {event_list}"
                else:
                    return f"You have no events {timeframe}."
            
            elif command.action == "calendar_create_event":
                if result.get("success"):
                    event = result.get("event", {})
                    return f"I've created the event: {event.get('summary', 'your event')}"
                else:
                    return f"Sorry, I couldn't create the event: {result.get('error', 'unknown error')}"
        
        # Camera responses
        elif command.intent == CommandIntent.CAMERA:
            if result.get("success"):
                return "I've taken a picture."
            else:
                return "Sorry, I couldn't take a picture."
        
        # Default response
        return result.get("message", "Command executed successfully.")
    
    async def process_voice_input(
        self,
        audio_bytes: bytes,
        voice_recognition_service,
        tts_service,
        language: str = "en-US"
    ) -> CommandResponse:
        """
        Complete voice command pipeline: recognize -> parse -> execute -> respond
        
        This is the main entry point for voice commands.
        """
        try:
            # 1. Recognize speech
            text = await voice_recognition_service.recognize(audio_bytes, language)
            if not text:
                return CommandResponse(
                    success=False,
                    message="I didn't catch that. Could you repeat?",
                    speak=True
                )
            
            logger.info(f"Voice input recognized: {text}")
            
            # 2. Parse command
            command = await self.parse_command(text)
            
            # 3. Execute command
            response = await self.execute_command(command)
            
            # 4. Speak response
            if response.speak and tts_service:
                await tts_service.speak(response.message, language=language)
            
            return response
            
        except Exception as e:
            logger.error(f"Voice input processing error: {e}")
            return CommandResponse(
                success=False,
                message="Sorry, I had trouble processing that command.",
                speak=True
            )
    
    def add_custom_pattern(self, intent: CommandIntent, pattern: str):
        """Add custom command pattern"""
        if intent not in self.command_patterns:
            self.command_patterns[intent] = []
        self.command_patterns[intent].append(pattern)
        logger.info(f"Added custom pattern for {intent.value}")
    
    def get_command_history(self, limit: int = 10) -> List[Dict]:
        """Get recent command history"""
        return self.command_history[-limit:]
    
    def clear_context(self):
        """Clear conversation context"""
        self.context = {}
    
    def set_context(self, key: str, value: Any):
        """Set context variable for conversation continuity"""
        self.context[key] = value


# Convenience function
async def create_voice_command_router(ai_service, mcp_server) -> VoiceCommandRouter:
    """Create and initialize voice command router"""
    router = VoiceCommandRouter()
    await router.initialize(ai_service, mcp_server)
    return router
