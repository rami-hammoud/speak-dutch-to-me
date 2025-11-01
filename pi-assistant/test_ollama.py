#!/usr/bin/env python3
"""
Test Ollama Integration - Run this on the Pi to debug the issue
"""

import asyncio
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ai_service import AIService, OllamaProvider, Message

async def test_ollama():
    print("🧪 Testing Ollama Integration...")
    print("="*60)
    
    # Initialize Ollama provider
    print("\n1. Initializing Ollama provider...")
    try:
        provider = OllamaProvider("http://localhost:11434", "llama3.2:3b")
        print("✅ Provider initialized")
    except Exception as e:
        print(f"❌ Failed to initialize: {e}")
        return
    
    # Test non-streaming chat
    print("\n2. Testing non-streaming chat...")
    try:
        messages = [Message(role="user", content="Say hello in one sentence")]
        response = await provider.chat_completion(messages, stream=False)
        print(f"✅ Response: {response.content}")
        print(f"   Model: {response.model}")
    except Exception as e:
        print(f"❌ Non-streaming failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test streaming chat
    print("\n3. Testing streaming chat...")
    try:
        messages = [Message(role="user", content="Count to 3")]
        print("✅ Stream chunks: ", end="", flush=True)
        async for chunk in provider.stream_chat_completion(messages):
            print(chunk, end="", flush=True)
        print("\n✅ Streaming complete")
    except Exception as e:
        print(f"\n❌ Streaming failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test via AIService
    print("\n4. Testing via AIService...")
    try:
        ai_service = AIService()
        ai_service.add_provider("ollama", provider)
        ai_service.set_provider("ollama")
        
        messages = [Message(role="user", content="What is 2+2?")]
        response = await ai_service.chat(messages)
        print(f"✅ AIService Response: {response.content}")
    except Exception as e:
        print(f"❌ AIService failed: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*60)
    print("✨ Test complete!")

if __name__ == "__main__":
    asyncio.run(test_ollama())
