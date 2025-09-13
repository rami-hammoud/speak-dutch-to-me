"""
Model Context Protocol (MCP) Server for Pi Assistant
Provides system commands and hardware control capabilities
"""

import asyncio
import json
import logging
import subprocess
import os
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class MCPTool:
    """Definition of an MCP tool"""
    name: str
    description: str
    input_schema: Dict[str, Any]
    handler: callable

class MCPServer:
    """MCP Server for system commands and hardware control"""
    
    def __init__(self):
        self.tools: Dict[str, MCPTool] = {}
        self._register_tools()
    
    def _register_tools(self):
        """Register all available MCP tools"""
        
        # System information tools
        self.register_tool(
            "system_info",
            "Get system information including CPU, memory, disk usage",
            {"type": "object", "properties": {}},
            self._get_system_info
        )
        
        self.register_tool(
            "list_processes",
            "List running processes",
            {
                "type": "object",
                "properties": {
                    "filter": {"type": "string", "description": "Filter processes by name"}
                }
            },
            self._list_processes
        )
        
        # File system tools
        self.register_tool(
            "list_files",
            "List files in a directory",
            {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Directory path"},
                    "show_hidden": {"type": "boolean", "default": False}
                },
                "required": ["path"]
            },
            self._list_files
        )
        
        self.register_tool(
            "read_file",
            "Read contents of a text file",
            {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "File path"},
                    "lines": {"type": "integer", "description": "Max lines to read"}
                },
                "required": ["path"]
            },
            self._read_file
        )
        
        # Hardware control tools
        self.register_tool(
            "gpio_control",
            "Control GPIO pins on Raspberry Pi",
            {
                "type": "object",
                "properties": {
                    "pin": {"type": "integer", "description": "GPIO pin number"},
                    "action": {"type": "string", "enum": ["read", "write"], "description": "Action to perform"},
                    "value": {"type": "boolean", "description": "Value to write (for write action)"}
                },
                "required": ["pin", "action"]
            },
            self._gpio_control
        )
        
        # Audio/Camera tools
        self.register_tool(
            "camera_capture",
            "Capture image from camera",
            {
                "type": "object",
                "properties": {
                    "filename": {"type": "string", "description": "Output filename"},
                    "width": {"type": "integer", "default": 640},
                    "height": {"type": "integer", "default": 480}
                }
            },
            self._camera_capture
        )
        
        self.register_tool(
            "play_sound",
            "Play an audio file",
            {
                "type": "object",
                "properties": {
                    "file_path": {"type": "string", "description": "Path to audio file"},
                    "volume": {"type": "number", "minimum": 0, "maximum": 1, "default": 0.8}
                },
                "required": ["file_path"]
            },
            self._play_sound
        )
        
        # Network tools
        self.register_tool(
            "network_status",
            "Get network status and connectivity",
            {"type": "object", "properties": {}},
            self._network_status
        )
        
        # Service control
        self.register_tool(
            "service_control",
            "Control system services",
            {
                "type": "object",
                "properties": {
                    "service": {"type": "string", "description": "Service name"},
                    "action": {"type": "string", "enum": ["start", "stop", "restart", "status"], "description": "Action to perform"}
                },
                "required": ["service", "action"]
            },
            self._service_control
        )
    
    def register_tool(self, name: str, description: str, input_schema: Dict[str, Any], handler: callable):
        """Register a new MCP tool"""
        self.tools[name] = MCPTool(name, description, input_schema, handler)
        logger.info(f"Registered MCP tool: {name}")
    
    async def execute_command(self, command: Dict[str, Any]) -> Dict[str, Any]:
        """Execute an MCP command"""
        try:
            tool_name = command.get("tool")
            arguments = command.get("arguments", {})
            
            if tool_name not in self.tools:
                return {
                    "success": False,
                    "error": f"Tool '{tool_name}' not found"
                }
            
            tool = self.tools[tool_name]
            result = await tool.handler(arguments)
            
            return {
                "success": True,
                "tool": tool_name,
                "result": result
            }
        
        except Exception as e:
            logger.error(f"MCP command execution error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def list_tools(self) -> List[Dict[str, Any]]:
        """List all available tools"""
        return [
            {
                "name": tool.name,
                "description": tool.description,
                "input_schema": tool.input_schema
            }
            for tool in self.tools.values()
        ]
    
    async def initialize(self):
        """Initialize the MCP server"""
        logger.info("MCP Server initialized")
    
    async def cleanup(self):
        """Cleanup resources"""
        logger.info("MCP Server cleanup complete")
    
    # Tool implementations
    
    async def _get_system_info(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get system information"""
        try:
            # CPU usage
            cpu_cmd = "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"
            cpu_result = await self._run_command(cpu_cmd)
            
            # Memory usage
            mem_cmd = "free -m"
            mem_result = await self._run_command(mem_cmd)
            
            # Disk usage
            disk_cmd = "df -h /"
            disk_result = await self._run_command(disk_cmd)
            
            # Temperature (Raspberry Pi specific)
            temp_cmd = "vcgencmd measure_temp"
            temp_result = await self._run_command(temp_cmd)
            
            return {
                "cpu_usage": cpu_result.strip(),
                "memory_info": mem_result.strip(),
                "disk_usage": disk_result.strip(),
                "temperature": temp_result.strip()
            }
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _list_processes(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """List running processes"""
        try:
            filter_name = args.get("filter", "")
            cmd = "ps aux"
            if filter_name:
                cmd += f" | grep {filter_name}"
            
            result = await self._run_command(cmd)
            return {"processes": result.strip().split('\n')}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _list_files(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """List files in directory"""
        try:
            path = args["path"]
            show_hidden = args.get("show_hidden", False)
            
            cmd = f"ls -la {path}" if show_hidden else f"ls -l {path}"
            result = await self._run_command(cmd)
            
            return {"files": result.strip().split('\n')}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _read_file(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Read file contents"""
        try:
            path = args["path"]
            lines = args.get("lines")
            
            if not os.path.exists(path):
                return {"error": "File not found"}
            
            cmd = f"head -n {lines} {path}" if lines else f"cat {path}"
            result = await self._run_command(cmd)
            
            return {"content": result}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _gpio_control(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Control GPIO pins"""
        try:
            pin = args["pin"]
            action = args["action"]
            
            if action == "read":
                # Use raspi-gpio to read pin state
                cmd = f"raspi-gpio get {pin}"
                result = await self._run_command(cmd)
                return {"pin": pin, "state": result.strip()}
            
            elif action == "write":
                value = args.get("value", False)
                level = "hi" if value else "lo"
                # Set pin as output and write value
                cmd1 = f"raspi-gpio set {pin} op"
                cmd2 = f"raspi-gpio set {pin} {level}"
                
                await self._run_command(cmd1)
                result = await self._run_command(cmd2)
                
                return {"pin": pin, "value": value, "result": "success"}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _camera_capture(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Capture image from camera"""
        try:
            filename = args.get("filename", "capture.jpg")
            width = args.get("width", 640)
            height = args.get("height", 480)
            
            # Use libcamera for Raspberry Pi
            cmd = f"libcamera-still -o {filename} --width {width} --height {height} --timeout 2000"
            result = await self._run_command(cmd)
            
            return {"filename": filename, "result": "success"}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _play_sound(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Play audio file"""
        try:
            file_path = args["file_path"]
            volume = args.get("volume", 0.8)
            
            if not os.path.exists(file_path):
                return {"error": "Audio file not found"}
            
            # Use aplay for audio playback
            cmd = f"aplay {file_path}"
            result = await self._run_command(cmd)
            
            return {"file": file_path, "result": "success"}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _network_status(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get network status"""
        try:
            # Get IP addresses
            ip_cmd = "ip addr show"
            ip_result = await self._run_command(ip_cmd)
            
            # Test connectivity
            ping_cmd = "ping -c 1 8.8.8.8"
            ping_result = await self._run_command(ping_cmd)
            
            return {
                "interfaces": ip_result.strip(),
                "connectivity": "online" if "1 received" in ping_result else "offline"
            }
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _service_control(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Control system services"""
        try:
            service = args["service"]
            action = args["action"]
            
            cmd = f"systemctl {action} {service}"
            result = await self._run_command(cmd)
            
            return {"service": service, "action": action, "result": result.strip()}
        
        except Exception as e:
            return {"error": str(e)}
    
    async def _run_command(self, command: str) -> str:
        """Run shell command asynchronously"""
        try:
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                error_msg = stderr.decode().strip()
                if error_msg:
                    raise Exception(f"Command failed: {error_msg}")
            
            return stdout.decode()
        
        except Exception as e:
            logger.error(f"Command execution error: {e}")
            raise e
