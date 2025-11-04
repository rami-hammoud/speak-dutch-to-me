"""
MCP Module: Personal Assistant
Handles calendar, tasks, notes, and email management with Google Calendar integration
"""

import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import re
from ..server import MCPTool

logger = logging.getLogger(__name__)

# Import Google Calendar service
try:
    import sys
    from pathlib import Path
    # Add services directory to path
    services_path = Path(__file__).parent.parent.parent / "services"
    if str(services_path) not in sys.path:
        sys.path.insert(0, str(services_path))
    
    from google_calendar_service import get_calendar_service
    CALENDAR_AVAILABLE = True
    logger.info("Google Calendar service imported successfully")
except ImportError as e:
    CALENDAR_AVAILABLE = False
    logger.warning(f"Google Calendar service not available: {e}")


class PersonalAssistantModule:
    """Personal assistant capabilities with Google Calendar integration"""
    
    def __init__(self):
        self.tools = []
        self._initialized = False
        self.calendar_service = None
    
    async def initialize(self):
        """Initialize personal assistant services"""
        logger.info("Initializing Personal Assistant Module...")
        
        # Initialize Google Calendar
        if CALENDAR_AVAILABLE:
            try:
                self.calendar_service = await get_calendar_service()
                logger.info("Google Calendar service initialized")
            except Exception as e:
                logger.warning(f"Could not initialize Google Calendar: {e}")
        
        # Register calendar tools
        self.tools.extend([
            MCPTool(
                name="calendar_list_events",
                description="List upcoming calendar events",
                input_schema={
                    "type": "object",
                    "properties": {
                        "days_ahead": {"type": "integer", "default": 7},
                        "calendar_id": {"type": "string"}
                    }
                },
                handler=self._list_calendar_events
            ),
            MCPTool(
                name="calendar_create_event",
                description="Create a new calendar event",
                input_schema={
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "start_time": {"type": "string"},
                        "end_time": {"type": "string"},
                        "description": {"type": "string"},
                        "location": {"type": "string"}
                    },
                    "required": ["title", "start_time"]
                },
                handler=self._create_calendar_event
            ),
            MCPTool(
                name="tasks_list",
                description="List tasks from task manager",
                input_schema={
                    "type": "object",
                    "properties": {
                        "filter": {"type": "string", "enum": ["all", "today", "overdue"]},
                        "project_id": {"type": "string"}
                    }
                },
                handler=self._list_tasks
            ),
            MCPTool(
                name="tasks_create",
                description="Create a new task",
                input_schema={
                    "type": "object",
                    "properties": {
                        "content": {"type": "string"},
                        "due_date": {"type": "string"},
                        "priority": {"type": "integer", "minimum": 1, "maximum": 4},
                        "project_id": {"type": "string"}
                    },
                    "required": ["content"]
                },
                handler=self._create_task
            ),
            MCPTool(
                name="email_search",
                description="Search emails",
                input_schema={
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "limit": {"type": "integer", "default": 10}
                    },
                    "required": ["query"]
                },
                handler=self._search_emails
            )
        ])
        
        self._initialized = True
        logger.info(f"Personal Assistant Module initialized with {len(self.tools)} tools")
    
    def get_tools(self) -> List[MCPTool]:
        """Get all available tools"""
        return self.tools
    
    async def _list_calendar_events(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """List calendar events"""
        if not self.calendar_service:
            return {
                "success": False,
                "error": "Calendar service not available",
                "events": []
            }
        
        try:
            timeframe = params.get("timeframe", "today")
            max_results = params.get("max_results", 10)
            
            if timeframe == "today":
                events = await self.calendar_service.get_today_events()
            elif timeframe == "week":
                events = await self.calendar_service.get_week_events()
            elif timeframe == "tomorrow":
                tomorrow = datetime.utcnow() + timedelta(days=1)
                start_of_day = tomorrow.replace(hour=0, minute=0, second=0, microsecond=0)
                end_of_day = start_of_day + timedelta(days=1)
                events = await self.calendar_service.list_events(
                    time_min=start_of_day,
                    time_max=end_of_day
                )
            else:
                events = await self.calendar_service.list_events(max_results=max_results)
            
            return {
                "success": True,
                "events": events,
                "count": len(events),
                "timeframe": timeframe
            }
        
        except Exception as e:
            logger.error(f"Error listing events: {e}")
            return {
                "success": False,
                "error": str(e),
                "events": []
            }
    
    async def _create_calendar_event(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Create calendar event"""
        if not self.calendar_service:
            return {
                "success": False,
                "error": "Calendar service not available"
            }
        
        try:
            title = params.get("title")
            start_time_str = params.get("start_time")
            duration_minutes = params.get("duration_minutes", 60)
            description = params.get("description", "")
            location = params.get("location", "")
            attendees = params.get("attendees", [])
            
            # Parse start time
            start_dt = self._parse_time(start_time_str)
            end_dt = start_dt + timedelta(minutes=duration_minutes)
            
            event = await self.calendar_service.create_event(
                summary=title,
                start_time=start_dt,
                end_time=end_dt,
                description=description,
                location=location,
                attendees=attendees
            )
            
            if event:
                return {
                    "success": True,
                    "event": event,
                    "message": f"Created event: {title}"
                }
            else:
                return {
                    "success": False,
                    "error": "Failed to create event"
                }
        
        except Exception as e:
            logger.error(f"Error creating event: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def _parse_time(self, time_str: str) -> datetime:
        """Parse natural language time expressions"""
        time_str = time_str.lower().strip()
        now = datetime.utcnow()
        
        # Try ISO format first
        try:
            return datetime.fromisoformat(time_str.replace('Z', '+00:00'))
        except:
            pass
        
        # Relative time patterns
        if "tomorrow" in time_str:
            base = now + timedelta(days=1)
            time_part = self._extract_time(time_str)
            if time_part:
                return base.replace(hour=time_part[0], minute=time_part[1], second=0, microsecond=0)
            return base.replace(hour=9, minute=0, second=0, microsecond=0)
        
        if "today" in time_str:
            time_part = self._extract_time(time_str)
            if time_part:
                return now.replace(hour=time_part[0], minute=time_part[1], second=0, microsecond=0)
            return now
        
        if "in" in time_str:
            # "in 2 hours", "in 30 minutes"
            match = re.search(r'in (\d+)\s*(hour|minute|day)', time_str)
            if match:
                amount = int(match.group(1))
                unit = match.group(2)
                if unit == 'hour':
                    return now + timedelta(hours=amount)
                elif unit == 'minute':
                    return now + timedelta(minutes=amount)
                elif unit == 'day':
                    return now + timedelta(days=amount)
        
        # Default to current time plus 1 hour
        return now + timedelta(hours=1)
    
    def _extract_time(self, text: str) -> Optional[tuple]:
        """Extract hour and minute from text like 'at 2pm' or 'at 14:30'"""
        patterns = [
            r'(\d{1,2}):(\d{2})\s*(am|pm)?',
            r'(\d{1,2})\s*(am|pm)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                hour = int(match.group(1))
                minute = int(match.group(2)) if len(match.groups()) > 1 and match.group(2).isdigit() else 0
                period = match.group(3) if len(match.groups()) > 2 else None
                
                if period:
                    if period == 'pm' and hour < 12:
                        hour += 12
                    elif period == 'am' and hour == 12:
                        hour = 0
                
                return (hour, minute)
        
        return None
    
    async def _list_tasks(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """List tasks"""
        # TODO: Implement Todoist/Things API integration
        return {
            "success": True,
            "tasks": [
                {"id": "1", "content": "Buy groceries", "priority": 2},
                {"id": "2", "content": "Review presentation", "priority": 3}
            ],
            "message": "Task integration not yet implemented"
        }
    
    async def _create_task(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Create task"""
        # TODO: Implement Todoist/Things API integration
        return {
            "success": True,
            "task_id": "placeholder",
            "message": f"Task '{params.get('content')}' would be created"
        }
    
    async def _search_emails(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Search emails"""
        # TODO: Implement Gmail API integration
        return {
            "success": True,
            "emails": [],
            "message": "Email integration not yet implemented"
        }
    
    async def cleanup(self):
        """Cleanup resources"""
        self._initialized = False
        logger.info("Personal Assistant Module cleaned up")
