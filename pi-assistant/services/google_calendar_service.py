"""
Google Calendar Service
Handles Google Calendar API authentication and operations
"""

import os
import pickle
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
from pathlib import Path

logger = logging.getLogger(__name__)

try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    GOOGLE_AVAILABLE = True
except ImportError:
    GOOGLE_AVAILABLE = False
    logger.warning("Google Calendar libraries not installed")

# If modifying these scopes, delete token.pickle
SCOPES = ['https://www.googleapis.com/auth/calendar']


class GoogleCalendarService:
    """Google Calendar API service"""
    
    def __init__(self, credentials_path: str = "credentials.json", token_path: str = "token.pickle"):
        self.credentials_path = Path(credentials_path)
        self.token_path = Path(token_path)
        self.creds = None
        self.service = None
        self.initialized = False
        
    async def initialize(self) -> bool:
        """Initialize Google Calendar service with OAuth"""
        if not GOOGLE_AVAILABLE:
            logger.error("Google Calendar libraries not available")
            return False
            
        try:
            # Load credentials from file
            if self.token_path.exists():
                with open(self.token_path, 'rb') as token:
                    self.creds = pickle.load(token)
            
            # If credentials don't exist or are invalid, authenticate
            if not self.creds or not self.creds.valid:
                if self.creds and self.creds.expired and self.creds.refresh_token:
                    self.creds.refresh(Request())
                else:
                    if not self.credentials_path.exists():
                        logger.error(f"Credentials file not found: {self.credentials_path}")
                        return False
                    
                    flow = InstalledAppFlow.from_client_secrets_file(
                        str(self.credentials_path), SCOPES)
                    self.creds = flow.run_local_server(port=0)
                
                # Save credentials
                with open(self.token_path, 'wb') as token:
                    pickle.dump(self.creds, token)
            
            # Build service
            self.service = build('calendar', 'v3', credentials=self.creds)
            self.initialized = True
            logger.info("Google Calendar service initialized")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize Google Calendar: {e}")
            return False
    
    async def list_events(
        self,
        max_results: int = 10,
        time_min: Optional[datetime] = None,
        time_max: Optional[datetime] = None,
        calendar_id: str = 'primary'
    ) -> List[Dict[str, Any]]:
        """
        List calendar events
        
        Args:
            max_results: Maximum number of events to return
            time_min: Start time (defaults to now)
            time_max: End time (defaults to 1 week from now)
            calendar_id: Calendar ID (defaults to 'primary')
        
        Returns:
            List of event dictionaries
        """
        if not self.initialized or not self.service:
            logger.error("Service not initialized")
            return []
        
        try:
            if time_min is None:
                time_min = datetime.utcnow()
            if time_max is None:
                time_max = time_min + timedelta(days=7)
            
            events_result = self.service.events().list(
                calendarId=calendar_id,
                timeMin=time_min.isoformat() + 'Z',
                timeMax=time_max.isoformat() + 'Z',
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            
            # Format events
            formatted_events = []
            for event in events:
                formatted_event = {
                    'id': event['id'],
                    'summary': event.get('summary', 'No title'),
                    'start': event['start'].get('dateTime', event['start'].get('date')),
                    'end': event['end'].get('dateTime', event['end'].get('date')),
                    'location': event.get('location', ''),
                    'description': event.get('description', ''),
                    'attendees': [a.get('email') for a in event.get('attendees', [])],
                    'html_link': event.get('htmlLink', '')
                }
                formatted_events.append(formatted_event)
            
            return formatted_events
            
        except HttpError as e:
            logger.error(f"Calendar API error: {e}")
            return []
        except Exception as e:
            logger.error(f"Error listing events: {e}")
            return []
    
    async def create_event(
        self,
        summary: str,
        start_time: datetime,
        end_time: datetime,
        description: str = "",
        location: str = "",
        attendees: List[str] = None,
        calendar_id: str = 'primary'
    ) -> Optional[Dict[str, Any]]:
        """
        Create a calendar event
        
        Args:
            summary: Event title
            start_time: Start datetime
            end_time: End datetime
            description: Event description
            location: Event location
            attendees: List of attendee emails
            calendar_id: Calendar ID
        
        Returns:
            Created event dictionary or None
        """
        if not self.initialized or not self.service:
            logger.error("Service not initialized")
            return None
        
        try:
            event = {
                'summary': summary,
                'location': location,
                'description': description,
                'start': {
                    'dateTime': start_time.isoformat(),
                    'timeZone': 'UTC',
                },
                'end': {
                    'dateTime': end_time.isoformat(),
                    'timeZone': 'UTC',
                },
            }
            
            if attendees:
                event['attendees'] = [{'email': email} for email in attendees]
            
            created_event = self.service.events().insert(
                calendarId=calendar_id,
                body=event
            ).execute()
            
            logger.info(f"Created event: {created_event.get('id')}")
            return {
                'id': created_event['id'],
                'summary': created_event.get('summary'),
                'start': created_event['start'].get('dateTime'),
                'end': created_event['end'].get('dateTime'),
                'html_link': created_event.get('htmlLink')
            }
            
        except HttpError as e:
            logger.error(f"Calendar API error: {e}")
            return None
        except Exception as e:
            logger.error(f"Error creating event: {e}")
            return None
    
    async def update_event(
        self,
        event_id: str,
        summary: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        description: Optional[str] = None,
        location: Optional[str] = None,
        calendar_id: str = 'primary'
    ) -> Optional[Dict[str, Any]]:
        """Update an existing event"""
        if not self.initialized or not self.service:
            return None
        
        try:
            # Get existing event
            event = self.service.events().get(
                calendarId=calendar_id,
                eventId=event_id
            ).execute()
            
            # Update fields
            if summary is not None:
                event['summary'] = summary
            if description is not None:
                event['description'] = description
            if location is not None:
                event['location'] = location
            if start_time is not None:
                event['start'] = {
                    'dateTime': start_time.isoformat(),
                    'timeZone': 'UTC',
                }
            if end_time is not None:
                event['end'] = {
                    'dateTime': end_time.isoformat(),
                    'timeZone': 'UTC',
                }
            
            updated_event = self.service.events().update(
                calendarId=calendar_id,
                eventId=event_id,
                body=event
            ).execute()
            
            logger.info(f"Updated event: {event_id}")
            return {
                'id': updated_event['id'],
                'summary': updated_event.get('summary'),
                'start': updated_event['start'].get('dateTime'),
                'end': updated_event['end'].get('dateTime')
            }
            
        except Exception as e:
            logger.error(f"Error updating event: {e}")
            return None
    
    async def delete_event(
        self,
        event_id: str,
        calendar_id: str = 'primary'
    ) -> bool:
        """Delete an event"""
        if not self.initialized or not self.service:
            return False
        
        try:
            self.service.events().delete(
                calendarId=calendar_id,
                eventId=event_id
            ).execute()
            
            logger.info(f"Deleted event: {event_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting event: {e}")
            return False
    
    async def search_events(
        self,
        query: str,
        max_results: int = 10,
        calendar_id: str = 'primary'
    ) -> List[Dict[str, Any]]:
        """Search for events by query"""
        if not self.initialized or not self.service:
            return []
        
        try:
            events_result = self.service.events().list(
                calendarId=calendar_id,
                q=query,
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            
            formatted_events = []
            for event in events:
                formatted_events.append({
                    'id': event['id'],
                    'summary': event.get('summary', 'No title'),
                    'start': event['start'].get('dateTime', event['start'].get('date')),
                    'end': event['end'].get('dateTime', event['end'].get('date')),
                    'description': event.get('description', ''),
                })
            
            return formatted_events
            
        except Exception as e:
            logger.error(f"Error searching events: {e}")
            return []
    
    async def get_today_events(self) -> List[Dict[str, Any]]:
        """Get today's events"""
        now = datetime.utcnow()
        start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = start_of_day + timedelta(days=1)
        
        return await self.list_events(
            time_min=start_of_day,
            time_max=end_of_day,
            max_results=50
        )
    
    async def get_week_events(self) -> List[Dict[str, Any]]:
        """Get this week's events"""
        now = datetime.utcnow()
        end_of_week = now + timedelta(days=7)
        
        return await self.list_events(
            time_min=now,
            time_max=end_of_week,
            max_results=50
        )


# Global service instance
_calendar_service = None

async def get_calendar_service() -> GoogleCalendarService:
    """Get or create calendar service instance"""
    global _calendar_service
    
    if _calendar_service is None:
        _calendar_service = GoogleCalendarService()
        await _calendar_service.initialize()
    
    return _calendar_service
