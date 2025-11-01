#!/usr/bin/env python3
"""Test Ollama streaming directly"""

import asyncio
from ai_service import OllamaProvider, Message

async def test():
    print("🧪 Testing Ollama streaming...")
    
    provider = OllamaProvider("http://localhost:11434", "llama3.2:3b")
    messages = [Message(role="user", content="Say hello!")]
    
    print("📤 Sending message...")
    
    chunk_count = 0
    full_response = ""
    
    async for chunk in provider.stream_chat_completion(messages):
        chunk_count += 1
        full_response += chunk
        print(f"Chunk {chunk_count}: '{chunk}'")
    
    print(f"\n✅ Complete! Total chunks: {chunk_count}")
    print(f"Full response: {full_response}")

if __name__ == "__main__":
    asyncio.run(test())
