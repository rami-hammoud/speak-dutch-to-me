#!/usr/bin/env python3
"""
Complete Voice Command System Demo
Demonstrates all capabilities: Shopping, Dutch Learning, Calendar, Camera
"""

import asyncio
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'


def print_section(title: str):
    """Print a formatted section header"""
    print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}{title.center(70)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.END}\n")


def print_command(text: str):
    """Print user command"""
    print(f"{Colors.CYAN}👤 You: {Colors.BOLD}{text}{Colors.END}")


def print_response(text: str, success: bool = True):
    """Print assistant response"""
    color = Colors.GREEN if success else Colors.RED
    icon = "🤖" if success else "❌"
    print(f"{color}{icon} Assistant: {text}{Colors.END}")


def print_info(text: str):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ️  {text}{Colors.END}")


async def demo_voice_shopping():
    """Demo: Voice-activated shopping"""
    print_section("🛒 VOICE SHOPPING DEMO")
    
    from services.voice_command_router import create_voice_command_router
    from ai_service import AIService, OllamaProvider
    from mcp.server import MCPServer
    
    # Initialize services
    print_info("Initializing shopping agent...")
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    # Test commands
    commands = [
        "Find me a wireless keyboard under 50 dollars",
        "Compare prices for wireless mouse",
        "Show my shopping cart",
    ]
    
    for cmd in commands:
        print_command(cmd)
        command = await router.parse_command(cmd)
        print_info(f"Intent: {command.intent.value} | Agent: {command.agent} | Action: {command.action}")
        
        response = await router.execute_command(command)
        print_response(response.message, response.success)
        print()


async def demo_dutch_learning():
    """Demo: Voice-activated Dutch learning"""
    print_section("🇳🇱 DUTCH LEARNING DEMO")
    
    from services.voice_command_router import create_voice_command_router
    from ai_service import AIService, OllamaProvider
    from mcp.server import MCPServer
    
    print_info("Initializing Dutch learning agent...")
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    commands = [
        "How do you say hello in Dutch",
        "What's the Dutch word for thank you",
        "Teach me the word for good morning",
    ]
    
    for cmd in commands:
        print_command(cmd)
        command = await router.parse_command(cmd)
        print_info(f"Intent: {command.intent.value} | Agent: {command.agent}")
        
        response = await router.execute_command(command)
        print_response(response.message, response.success)
        print()


async def demo_calendar():
    """Demo: Voice-activated calendar management"""
    print_section("📅 CALENDAR MANAGEMENT DEMO")
    
    from services.voice_command_router import create_voice_command_router
    from ai_service import AIService, OllamaProvider
    from mcp.server import MCPServer
    
    print_info("Initializing personal assistant with calendar...")
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    commands = [
        "What's on my calendar today",
        "Do I have any meetings tomorrow",
        "Schedule a team meeting for tomorrow at 2 PM",
        "What's my schedule this week",
    ]
    
    for cmd in commands:
        print_command(cmd)
        command = await router.parse_command(cmd)
        print_info(f"Intent: {command.intent.value} | Agent: {command.agent} | Action: {command.action}")
        
        response = await router.execute_command(command)
        print_response(response.message, response.success)
        print()


async def demo_camera():
    """Demo: Voice-activated camera"""
    print_section("📸 CAMERA DEMO")
    
    from services.voice_command_router import create_voice_command_router
    from ai_service import AIService, OllamaProvider
    from mcp.server import MCPServer
    
    print_info("Initializing camera...")
    ai = AIService()
    ai.add_provider("ollama", OllamaProvider(model="llama3.2:3b"))
    mcp = MCPServer()
    await mcp.initialize()
    router = await create_voice_command_router(ai, mcp)
    
    commands = [
        "Take a picture",
        "Capture a photo",
    ]
    
    for cmd in commands:
        print_command(cmd)
        command = await router.parse_command(cmd)
        print_info(f"Intent: {command.intent.value} | Agent: {command.agent}")
        
        response = await router.execute_command(command)
        print_response(response.message, response.success)
        print()


async def demo_pattern_matching():
    """Demo: Pattern matching accuracy"""
    print_section("🎯 PATTERN MATCHING ACCURACY TEST")
    
    from services.voice_command_router import VoiceCommandRouter
    
    router = VoiceCommandRouter()
    
    test_cases = [
        ("Find me a laptop under 1000 dollars", "shopping"),
        ("What's Dutch for hello", "dutch_learning"),
        ("Turn on the lights", "home_automation"),
        ("What's on my calendar", "information"),
        ("Take a photo", "camera"),
        ("Schedule a meeting tomorrow", "information"),
    ]
    
    correct = 0
    total = len(test_cases)
    
    for text, expected_intent in test_cases:
        command = await router.parse_command(text, use_ai=False)
        actual_intent = command.intent.value
        is_correct = actual_intent == expected_intent
        
        if is_correct:
            correct += 1
        
        status = "✅" if is_correct else "❌"
        print(f"{status} '{text}'")
        print(f"   Expected: {expected_intent} | Got: {actual_intent} | Confidence: {command.confidence:.2f}")
        print()
    
    accuracy = (correct / total) * 100
    print_info(f"Pattern Matching Accuracy: {accuracy:.1f}% ({correct}/{total})")


async def demo_web_ui_info():
    """Show web UI access information"""
    print_section("🌐 WEB INTERFACE")
    
    print(f"{Colors.BOLD}Voice Chat Interface:{Colors.END}")
    print(f"  {Colors.CYAN}http://localhost:8080/voice-chat{Colors.END}")
    print()
    print("Features:")
    print("  • 🎤 Click microphone to record voice commands")
    print("  • 🇺🇸🇳🇱 Switch between English and Dutch")
    print("  • 💬 Real-time chat history with intent badges")
    print("  • 🔊 Audio playback of responses")
    print("  • ⌨️  Keyboard shortcut: Hold SPACE to record")
    print()
    
    print(f"{Colors.BOLD}Available Commands:{Colors.END}")
    print()
    print(f"{Colors.YELLOW}Shopping:{Colors.END}")
    print("  • 'Find me a wireless keyboard'")
    print("  • 'Compare prices for a mouse'")
    print()
    print(f"{Colors.YELLOW}Dutch Learning:{Colors.END}")
    print("  • 'How do you say hello in Dutch'")
    print("  • 'What's the Dutch word for thank you'")
    print()
    print(f"{Colors.YELLOW}Calendar:{Colors.END}")
    print("  • 'What's on my calendar today'")
    print("  • 'Schedule a meeting for tomorrow at 2 PM'")
    print()
    print(f"{Colors.YELLOW}Camera:{Colors.END}")
    print("  • 'Take a picture'")
    print("  • 'Capture a photo'")


async def main():
    """Run all demos"""
    print(f"\n{Colors.BOLD}{Colors.HEADER}")
    print("╔═══════════════════════════════════════════════════════════════════╗")
    print("║                                                                   ║")
    print("║          🎙️  PI ASSISTANT VOICE COMMAND SYSTEM DEMO 🎙️           ║")
    print("║                                                                   ║")
    print("║  Complete AI-Powered Voice Assistant with MCP Agent Routing      ║")
    print("║                                                                   ║")
    print("╚═══════════════════════════════════════════════════════════════════╝")
    print(f"{Colors.END}\n")
    
    print_info(f"Demo started at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    try:
        # Run demos
        await demo_pattern_matching()
        await demo_voice_shopping()
        await demo_dutch_learning()
        await demo_calendar()
        await demo_camera()
        demo_web_ui_info()
        
        # Summary
        print_section("✅ DEMO COMPLETE")
        print(f"{Colors.GREEN}All voice command features demonstrated successfully!{Colors.END}")
        print()
        print(f"{Colors.BOLD}Next Steps:{Colors.END}")
        print(f"  1. Start the assistant: {Colors.CYAN}python main.py{Colors.END}")
        print(f"  2. Open voice chat: {Colors.CYAN}http://localhost:8080/voice-chat{Colors.END}")
        print(f"  3. Set up Google Calendar: {Colors.CYAN}See GOOGLE_CALENDAR_SETUP.md{Colors.END}")
        print()
        
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Demo interrupted by user{Colors.END}")
    except Exception as e:
        print(f"\n{Colors.RED}Error during demo: {e}{Colors.END}")
        logger.exception("Demo error")


if __name__ == "__main__":
    asyncio.run(main())
