"""
AI Service that handles both OpenAI and Ollama integrations
"""

import asyncio
import json
import logging
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Dict, List, Optional, Any
import aiohttp
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class Message:
    role: str
    content: str
    timestamp: Optional[str] = None

@dataclass
class ChatResponse:
    content: str
    model: str
    usage: Optional[Dict[str, Any]] = None

class AIProvider(ABC):
    """Abstract base class for AI providers"""
    
    @abstractmethod
    async def chat_completion(self, messages: List[Message], stream: bool = False) -> ChatResponse:
        pass
    
    @abstractmethod
    async def stream_chat_completion(self, messages: List[Message]) -> AsyncGenerator[str, None]:
        pass

class OpenAIProvider(AIProvider):
    """OpenAI API provider"""
    
    def __init__(self, api_key: str, model: str = "gpt-4"):
        self.api_key = api_key
        self.model = model
        self.base_url = "https://api.openai.com/v1"
    
    async def chat_completion(self, messages: List[Message], stream: bool = False) -> ChatResponse:
        """Send chat completion request to OpenAI"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": [{"role": msg.role, "content": msg.content} for msg in messages],
            "stream": stream
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload
            ) as response:
                if response.status != 200:
                    error_text = await response.text()
                    raise Exception(f"OpenAI API error: {response.status} - {error_text}")
                
                result = await response.json()
                return ChatResponse(
                    content=result["choices"][0]["message"]["content"],
                    model=self.model,
                    usage=result.get("usage")
                )
    
    async def stream_chat_completion(self, messages: List[Message]) -> AsyncGenerator[str, None]:
        """Stream chat completion from OpenAI"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": [{"role": msg.role, "content": msg.content} for msg in messages],
            "stream": True
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload
            ) as response:
                async for line in response.content:
                    line_str = line.decode('utf-8').strip()
                    if line_str.startswith('data: '):
                        data_str = line_str[6:]
                        if data_str == '[DONE]':
                            break
                        try:
                            data = json.loads(data_str)
                            if 'choices' in data and len(data['choices']) > 0:
                                delta = data['choices'][0].get('delta', {})
                                content = delta.get('content', '')
                                if content:
                                    yield content
                        except json.JSONDecodeError:
                            continue

class OllamaProvider(AIProvider):
    """Ollama local AI provider"""
    
    def __init__(self, host: str = "http://localhost:11434", model: str = "llama3.2"):
        self.host = host.rstrip('/')
        self.model = model
    
    async def chat_completion(self, messages: List[Message], stream: bool = False) -> ChatResponse:
        """Send chat completion request to Ollama"""
        payload = {
            "model": self.model,
            "messages": [{"role": msg.role, "content": msg.content} for msg in messages],
            "stream": False
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.host}/api/chat",
                json=payload
            ) as response:
                if response.status != 200:
                    error_text = await response.text()
                    raise Exception(f"Ollama API error: {response.status} - {error_text}")
                
                result = await response.json()
                return ChatResponse(
                    content=result["message"]["content"],
                    model=self.model,
                    usage=result.get("usage")
                )
    
    async def stream_chat_completion(self, messages: List[Message]) -> AsyncGenerator[str, None]:
        """Stream chat completion from Ollama"""
        payload = {
            "model": self.model,
            "messages": [{"role": msg.role, "content": msg.content} for msg in messages],
            "stream": True
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.host}/api/chat",
                json=payload
            ) as response:
                async for line in response.content:
                    try:
                        data = json.loads(line.decode('utf-8'))
                        if 'message' in data and 'content' in data['message']:
                            content = data['message']['content']
                            if content:
                                yield content
                        if data.get('done', False):
                            break
                    except json.JSONDecodeError:
                        continue

class AIService:
    """Main AI service that manages providers"""
    
    def __init__(self):
        self.providers: Dict[str, AIProvider] = {}
        self.current_provider = "ollama"  # Default to local
    
    def add_provider(self, name: str, provider: AIProvider):
        """Add an AI provider"""
        self.providers[name] = provider
        logger.info(f"Added AI provider: {name}")
    
    def set_provider(self, name: str):
        """Set the active provider"""
        if name not in self.providers:
            raise ValueError(f"Provider '{name}' not found")
        self.current_provider = name
        logger.info(f"Switched to AI provider: {name}")
    
    def get_provider(self) -> AIProvider:
        """Get the current provider"""
        if self.current_provider not in self.providers:
            raise ValueError(f"Current provider '{self.current_provider}' not available")
        return self.providers[self.current_provider]
    
    async def chat(self, messages: List[Message], stream: bool = False) -> ChatResponse:
        """Send chat completion request"""
        provider = self.get_provider()
        return await provider.chat_completion(messages, stream)
    
    async def stream_chat(self, messages: List[Message]) -> AsyncGenerator[str, None]:
        """Stream chat completion"""
        provider = self.get_provider()
        async for chunk in provider.stream_chat_completion(messages):
            yield chunk
    
    def list_providers(self) -> List[str]:
        """List available providers"""
        return list(self.providers.keys())
    
    async def test_provider(self, name: str) -> bool:
        """Test if a provider is working"""
        try:
            if name not in self.providers:
                return False
            
            provider = self.providers[name]
            test_messages = [Message(role="user", content="Hello, are you working?")]
            response = await provider.chat_completion(test_messages)
            return bool(response.content)
        except Exception as e:
            logger.error(f"Provider {name} test failed: {e}")
            return False
