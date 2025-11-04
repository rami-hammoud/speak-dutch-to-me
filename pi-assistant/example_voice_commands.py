"""
Example usage of Voice Command System with MCP Agents
Demonstrates shopping, Dutch learning, camera, and home automation
"""

import asyncio
import logging
from pathlib import Path

# Import services
from services.voice_recognition_service import create_voice_service
from services.tts_service import create_tts_service
from services.voice_command_router import create_voice_command_router, CommandIntent

# Import AI and MCP
from ai_service import AIService, OllamaProvider
from mcp.server import MCPServer

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def example_voice_shopping():
    """Example: Voice-activated shopping"""
    print("\n" + "=" * 60)
    print("🛒 VOICE SHOPPING EXAMPLE")
    print("=" * 60)
    
    # Initialize services
    voice = await create_voice_service()
    tts = await create_tts_service()
    
    # Initialize AI
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    
    # Initialize MCP
    mcp = MCPServer()
    await mcp.initialize()
    
    # Create voice command router
    router = await create_voice_command_router(ai, mcp)
    
    # Simulate voice commands
    test_commands = [
        "Find me a keyboard under $50",
        "Compare prices for wireless mouse",
        "Add the keyboard to my cart",
        "Show my shopping cart",
    ]
    
    for command_text in test_commands:
        print(f"\n👤 User says: \"{command_text}\"")
        
        # Parse command
        command = await router.parse_command(command_text)
        print(f"🤖 Detected intent: {command.intent.value}")
        print(f"   Agent: {command.agent}")
        print(f"   Action: {command.action}")
        print(f"   Parameters: {command.parameters}")
        
        # Execute command
        response = await router.execute_command(command)
        print(f"📢 Response: {response.message}")
        
        # TTS would speak the response
        # await tts.speak(response.message, language="en-US")
        
        print()


async def example_voice_dutch_learning():
    """Example: Voice-activated Dutch learning"""
    print("\n" + "=" * 60)
    print("🇳🇱 DUTCH LEARNING EXAMPLE")
    print("=" * 60)
    
    # Initialize services
    voice = await create_voice_service()
    tts = await create_tts_service()
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    test_commands = [
        "How do you say hello in Dutch",
        "Teach me the Dutch word for thank you",
        "Show my vocabulary",
        "Save the word goedemorgen",
    ]
    
    for command_text in test_commands:
        print(f"\n👤 User says: \"{command_text}\"")
        command = await router.parse_command(command_text)
        print(f"🤖 Intent: {command.intent.value} → {command.action}")
        
        response = await router.execute_command(command)
        print(f"📢 Response: {response.message}")


async def example_voice_camera():
    """Example: Voice-activated camera"""
    print("\n" + "=" * 60)
    print("📸 CAMERA CONTROL EXAMPLE")
    print("=" * 60)
    
    voice = await create_voice_service()
    tts = await create_tts_service()
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    test_commands = [
        "Take a picture",
        "Show the camera",
        "What is this object",
    ]
    
    for command_text in test_commands:
        print(f"\n👤 User says: \"{command_text}\"")
        command = await router.parse_command(command_text)
        print(f"🤖 Intent: {command.intent.value} → {command.action}")
        
        response = await router.execute_command(command)
        print(f"📢 Response: {response.message}")


async def example_home_automation():
    """Example: Voice-activated home automation (future)"""
    print("\n" + "=" * 60)
    print("🏠 HOME AUTOMATION EXAMPLE (Future)")
    print("=" * 60)
    
    voice = await create_voice_service()
    tts = await create_tts_service()
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    test_commands = [
        "Turn on the living room lights",
        "Set temperature to 22 degrees",
        "Lock the front door",
        "What's the temperature in the bedroom",
    ]
    
    for command_text in test_commands:
        print(f"\n👤 User says: \"{command_text}\"")
        command = await router.parse_command(command_text)
        print(f"🤖 Intent: {command.intent.value}")
        print(f"   Would control: {command.parameters}")
        print(f"   (Home automation not yet integrated)")


async def example_complete_conversation():
    """Example: Complete voice conversation with multiple intents"""
    print("\n" + "=" * 60)
    print("💬 COMPLETE CONVERSATION EXAMPLE")
    print("=" * 60)
    
    voice = await create_voice_service()
    tts = await create_tts_service()
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    # Simulated conversation
    conversation = [
        "How do you say keyboard in Dutch",  # Dutch learning
        "Find me a keyboard under $50",      # Shopping
        "Take a picture of it",              # Camera
        "Add it to my cart",                 # Shopping
        "Turn on the desk lamp",             # Home automation (future)
    ]
    
    print("\n🎬 Starting conversation...")
    
    for i, command_text in enumerate(conversation, 1):
        print(f"\n--- Turn {i} ---")
        print(f"👤 User: \"{command_text}\"")
        
        # Parse and execute
        command = await router.parse_command(command_text)
        response = await router.execute_command(command)
        
        print(f"🤖 [{command.intent.value}] {response.message}")
        
        # In real app: await tts.speak(response.message)
        await asyncio.sleep(0.5)  # Simulate speech
    
    # Show history
    print("\n📊 Conversation History:")
    history = router.get_command_history()
    for entry in history:
        print(f"  - {entry['command']} [{entry['intent']}]")


async def example_custom_patterns():
    """Example: Adding custom command patterns"""
    print("\n" + "=" * 60)
    print("⚙️  CUSTOM PATTERNS EXAMPLE")
    print("=" * 60)
    
    voice = await create_voice_service()
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    # Add custom patterns
    router.add_custom_pattern(
        CommandIntent.SHOPPING,
        r"I need (?:a|an|some)\s+(.+)"
    )
    
    router.add_custom_pattern(
        CommandIntent.HOME_AUTOMATION,
        r"(?:activate|deactivate)\s+(.+)"
    )
    
    print("✅ Added custom patterns")
    
    # Test new patterns
    test_commands = [
        "I need a new phone",           # Custom shopping pattern
        "activate security system",      # Custom home automation pattern
    ]
    
    for command_text in test_commands:
        print(f"\n👤 User: \"{command_text}\"")
        command = await router.parse_command(command_text)
        print(f"🤖 Matched intent: {command.intent.value}")
        print(f"   Entities: {command.entities}")


async def main():
    """Run all examples"""
    try:
        # Run examples
        await example_voice_shopping()
        await example_voice_dutch_learning()
        await example_voice_camera()
        await example_home_automation()
        await example_complete_conversation()
        await example_custom_patterns()
        
        print("\n" + "=" * 60)
        print("✅ All examples completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
