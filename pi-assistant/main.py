import asyncio
import logging
import os
import signal
import sys
from typing import Optional

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.requests import Request
from fastapi.responses import HTMLResponse
import uvicorn

from config import config
from ai_service import AIService, OpenAIProvider, OllamaProvider, Message
from mcp.server import MCPServer
from ui.audio_manager import AudioManager
from ui.camera_manager import CameraManager

# Setup logging
logging.basicConfig(
    level=logging.INFO if config.DEBUG else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'{config.LOGS_DIR}/assistant.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class PiAssistant:
    """Main Pi Assistant application"""
    
    def __init__(self):
        self.app = FastAPI(title="Pi Assistant", version="1.0.0")
        self.ai_service = AIService()
        self.mcp_server = MCPServer()
        self.audio_manager = AudioManager()
        self.camera_manager = CameraManager()
        
        # Active connections for WebSocket
        self.connections = set()
        
        # Setup routes
        self._setup_routes()
        self._setup_static_files()
        
    def _setup_static_files(self):
        """Setup static files and templates"""
        self.app.mount("/static", StaticFiles(directory="static"), name="static")
        self.templates = Jinja2Templates(directory="templates")
        
    def _setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.get("/", response_class=HTMLResponse)
        async def index(request: Request):
            return self.templates.TemplateResponse(
                "index.html", 
                {
                    "request": request,
                    "config": config,
                    "providers": self.ai_service.list_providers(),
                    "current_provider": self.ai_service.current_provider
                }
            )
        
        @self.app.get("/diagnostic", response_class=HTMLResponse)
        async def diagnostic(request: Request):
            return self.templates.TemplateResponse(
                "diagnostic.html",
                {"request": request}
            )
        
        @self.app.websocket("/ws")
        async def websocket_endpoint(websocket: WebSocket):
            await websocket.accept()
            self.connections.add(websocket)
            
            try:
                while True:
                    data = await websocket.receive_json()
                    await self._handle_websocket_message(websocket, data)
            except WebSocketDisconnect:
                self.connections.remove(websocket)
            except Exception as e:
                logger.error(f"WebSocket error: {e}")
                self.connections.discard(websocket)
        
        @self.app.post("/api/chat")
        async def chat_endpoint(request: dict):
            """REST API endpoint for chat"""
            try:
                messages = [Message(**msg) for msg in request.get("messages", [])]
                response = await self.ai_service.chat(messages)
                return {
                    "content": response.content,
                    "model": response.model,
                    "provider": self.ai_service.current_provider
                }
            except Exception as e:
                logger.error(f"Chat error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.post("/api/provider")
        async def set_provider(request: dict):
            """Change AI provider"""
            try:
                provider_name = request.get("provider")
                self.ai_service.set_provider(provider_name)
                return {"success": True, "provider": provider_name}
            except Exception as e:
                logger.error(f"Provider change error: {e}")
                raise HTTPException(status_code=400, detail=str(e))
        
        @self.app.get("/api/providers")
        async def get_providers():
            """Get available providers"""
            return {
                "providers": self.ai_service.list_providers(),
                "current": self.ai_service.current_provider
            }
        
        @self.app.get("/api/ollama/status")
        async def ollama_status():
            """Check Ollama status"""
            try:
                import aiohttp
                async with aiohttp.ClientSession() as session:
                    async with session.get(f"{config.OLLAMA_HOST}/api/tags", timeout=aiohttp.ClientTimeout(total=5)) as response:
                        if response.status == 200:
                            data = await response.json()
                            return {
                                "status": "online",
                                "models": [m["name"] for m in data.get("models", [])],
                                "host": config.OLLAMA_HOST
                            }
                        else:
                            return {"status": "error", "message": f"HTTP {response.status}"}
            except Exception as e:
                return {"status": "offline", "error": str(e)}
        
        @self.app.post("/api/audio/start")
        async def start_audio():
            """Start audio recording"""
            try:
                await self.audio_manager.start_recording()
                return {"success": True}
            except Exception as e:
                logger.error(f"Audio start error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.post("/api/audio/stop")
        async def stop_audio():
            """Stop audio recording and get transcription"""
            try:
                transcription = await self.audio_manager.stop_recording()
                return {"transcription": transcription}
            except Exception as e:
                logger.error(f"Audio stop error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/api/camera/frame")
        async def get_camera_frame():
            """Get current camera frame"""
            try:
                frame = await self.camera_manager.get_frame()
                if frame:
                    return {"frame": frame, "success": True}
                else:
                    return {"frame": None, "success": False, "error": "No frame available"}
            except Exception as e:
                logger.error(f"Camera error: {e}")
                return {"frame": None, "success": False, "error": str(e)}
        
        @self.app.get("/api/camera/status")
        async def get_camera_status():
            """Get camera status"""
            try:
                camera_info = self.camera_manager.get_camera_info()
                status = {
                    "available": camera_info["available"],
                    "streaming": camera_info["streaming"],
                    "camera_type": camera_info["type"] or "None",
                    "pi_camera": camera_info["pi_camera"],
                    "usb_camera": camera_info["usb_camera"],
                    "has_current_frame": self.camera_manager.current_frame is not None
                }
                return status
            except Exception as e:
                logger.error(f"Camera status error: {e}")
                return {"available": False, "streaming": False, "error": str(e)}
        
        @self.app.get("/dutch-learning", response_class=HTMLResponse)
        async def dutch_learning_page(request: Request):
            """Dutch learning page"""
            return self.templates.TemplateResponse(
                "dutch_learning.html",
                {"request": request}
            )
        
        @self.app.get("/api/dutch/stats")
        async def get_dutch_stats():
            """Get Dutch learning statistics"""
            try:
                result = await self.mcp_server.execute_tool("dutch_progress_stats", {"period": "week"})
                streak = await self.mcp_server.execute_tool("dutch_streak_info", {})
                return {
                    **result.get("stats", {}),
                    "current_streak": streak.get("current_streak", 0)
                }
            except Exception as e:
                logger.error(f"Error getting stats: {e}")
                return {"error": str(e)}
        
        @self.app.get("/api/dutch/review-words")
        async def get_review_words(count: int = 10):
            """Get words for review"""
            try:
                result = await self.mcp_server.execute_tool("dutch_vocabulary_review", {"count": count})
                return result
            except Exception as e:
                logger.error(f"Error getting review words: {e}")
                return {"words": []}
        
        @self.app.get("/api/dutch/vocabulary")
        async def search_vocabulary(query: str = "", limit: int = 50):
            """Search vocabulary"""
            try:
                if query:
                    result = await self.mcp_server.execute_tool("dutch_vocabulary_search", {"query": query})
                else:
                    result = await self.mcp_server.execute_tool("dutch_vocabulary_review", {"count": limit})
                return {"words": result.get("results", result.get("words", []))}
            except Exception as e:
                logger.error(f"Error searching vocabulary: {e}")
                return {"words": []}
        
        @self.app.post("/api/dutch/vocabulary")
        async def add_vocabulary(request: dict):
            """Add new vocabulary"""
            try:
                result = await self.mcp_server.execute_tool("dutch_vocabulary_add", request)
                return result
            except Exception as e:
                logger.error(f"Error adding vocabulary: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/api/dutch/exercises")
        async def get_exercises(topic: str = "articles", difficulty: str = "easy", count: int = 5):
            """Get grammar exercises"""
            try:
                result = await self.mcp_server.execute_tool("dutch_grammar_exercise", {
                    "topic": topic,
                    "difficulty": difficulty,
                    "count": count
                })
                return result
            except Exception as e:
                logger.error(f"Error getting exercises: {e}")
                return {"exercises": []}
        
        @self.app.post("/api/dutch/conversation/start")
        async def start_conversation(request: dict):
            """Start conversation practice"""
            try:
                result = await self.mcp_server.execute_tool("dutch_conversation_practice", request)
                return result
            except Exception as e:
                logger.error(f"Error starting conversation: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/api/dutch/daily-challenge")
        async def get_daily_challenge():
            """Get daily challenge"""
            try:
                result = await self.mcp_server.execute_tool("dutch_daily_challenge", {})
                return result
            except Exception as e:
                logger.error(f"Error getting challenge: {e}")
                return {"challenge": None}
        
        @self.app.post("/api/dutch/translate")
        async def translate_text(request: dict):
            """Translate text"""
            try:
                result = await self.mcp_server.execute_tool("dutch_translate", request)
                return result
            except Exception as e:
                logger.error(f"Error translating: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        # ...existing code...
        
    async def _handle_websocket_message(self, websocket: WebSocket, data: dict):
        """Handle incoming WebSocket messages"""
        try:
            message_type = data.get("type")
            logger.info(f"WebSocket message type: {message_type}")
            
            if message_type == "chat":
                messages_data = data.get("messages", [])
                logger.info(f"Chat request with {len(messages_data)} messages")
                messages = [Message(**msg) for msg in messages_data]
                
                # Send streaming response
                await websocket.send_json({"type": "chat_start"})
                logger.info("Streaming chat response...")
                
                full_response = ""
                chunk_count = 0
                try:
                    async for chunk in self.ai_service.stream_chat(messages):
                        chunk_count += 1
                        full_response += chunk
                        logger.debug(f"Chunk {chunk_count}: {chunk}")
                        await websocket.send_json({
                            "type": "chat_chunk",
                            "content": chunk
                        })
                except Exception as e:
                    logger.error(f"Error during streaming: {e}", exc_info=True)
                    await websocket.send_json({
                        "type": "error",
                        "message": str(e)
                    })
                    return
                
                await websocket.send_json({
                    "type": "chat_complete",
                    "content": full_response
                })
                logger.info(f"Chat complete. Chunks: {chunk_count}, Response length: {len(full_response)}")
            
            elif message_type == "audio_data":
                # Handle audio data for real-time processing
                audio_data = data.get("data")
                transcription = await self.audio_manager.process_audio_chunk(audio_data)
                if transcription:
                    await websocket.send_json({
                        "type": "transcription",
                        "content": transcription
                    })
            
            elif message_type == "system_command":
                # Handle system commands via MCP
                command = data.get("command")
                result = await self.mcp_server.execute_command(command)
                await websocket.send_json({
                    "type": "command_result",
                    "result": result
                })
        
        except Exception as e:
            logger.error(f"WebSocket message handling error: {e}")
            await websocket.send_json({
                "type": "error",
                "message": str(e)
            })
    
    async def initialize(self):
        """Initialize all services"""
        logger.info("Initializing Pi Assistant...")
        
        # Initialize AI providers
        if config.OPENAI_API_KEY:
            openai_provider = OpenAIProvider(config.OPENAI_API_KEY, config.OPENAI_MODEL)
            self.ai_service.add_provider("openai", openai_provider)
            logger.info("OpenAI provider initialized")
        
        # Initialize Ollama provider
        try:
            ollama_provider = OllamaProvider(config.OLLAMA_HOST, config.OLLAMA_MODEL)
            self.ai_service.add_provider("ollama", ollama_provider)
            logger.info("Ollama provider initialized")
        except Exception as e:
            logger.warning(f"Ollama provider failed to initialize: {e}")
        
        # Set default provider
        if self.ai_service.list_providers():
            if "ollama" in self.ai_service.list_providers():
                self.ai_service.set_provider("ollama")
            else:
                self.ai_service.set_provider(self.ai_service.list_providers()[0])
        
        # Initialize other services
        await self.mcp_server.initialize()
        await self.audio_manager.initialize()
        await self.camera_manager.initialize()
        
        logger.info("Pi Assistant initialization complete")
    
    async def cleanup(self):
        """Cleanup resources"""
        logger.info("Cleaning up Pi Assistant...")
        
        # Close all WebSocket connections
        for connection in self.connections.copy():
            try:
                await connection.close()
            except:
                pass
        
        # Cleanup services
        await self.mcp_server.cleanup()
        await self.audio_manager.cleanup()
        await self.camera_manager.cleanup()
        
        logger.info("Pi Assistant cleanup complete")

# Global instance
assistant = PiAssistant()

async def startup():
    """Application startup"""
    await assistant.initialize()

async def shutdown():
    """Application shutdown"""
    await assistant.cleanup()

# Add event handlers
assistant.app.add_event_handler("startup", startup)
assistant.app.add_event_handler("shutdown", shutdown)

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}, shutting down...")
    asyncio.create_task(assistant.cleanup())
    sys.exit(0)

if __name__ == "__main__":
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run the application
    uvicorn.run(
        "main:assistant.app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info" if config.DEBUG else "warning"
    )