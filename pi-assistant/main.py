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
        async def home(request: Request):
            return self.templates.TemplateResponse(
                "index.html", 
                {
                    "request": request,
                    "config": config,
                    "providers": self.ai_service.list_providers(),
                    "current_provider": self.ai_service.current_provider
                }
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
                return {"frame": frame}
            except Exception as e:
                logger.error(f"Camera error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
    
    async def _handle_websocket_message(self, websocket: WebSocket, data: dict):
        """Handle incoming WebSocket messages"""
        try:
            message_type = data.get("type")
            
            if message_type == "chat":
                messages = [Message(**msg) for msg in data.get("messages", [])]
                
                # Send streaming response
                await websocket.send_json({"type": "chat_start"})
                
                full_response = ""
                async for chunk in self.ai_service.stream_chat(messages):
                    full_response += chunk
                    await websocket.send_json({
                        "type": "chat_chunk",
                        "content": chunk
                    })
                
                await websocket.send_json({
                    "type": "chat_complete",
                    "content": full_response
                })
            
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