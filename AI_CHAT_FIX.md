# AI Chat Fix - November 1, 2025

## Problem
The AI assistant chat was returning a 404 error when trying to stream responses from Ollama.

## Root Cause
The Ollama model name in `config.py` was incomplete. It was set to `"llama3.2"` but Ollama requires the full model tag including the size parameter, which should be `"llama3.2:3b"`.

## Solution

### 1. Fixed Model Name in config.py
**Changed:**
```python
OLLAMA_MODEL: str = "llama3.2"
```

**To:**
```python
OLLAMA_MODEL: str = "llama3.2:3b"
```

### 2. Improved Error Logging in ai_service.py
Added better logging and timeouts to help diagnose issues:
- Added detailed payload logging
- Added explicit URL logging
- Added timeout configuration (300 seconds)
- Improved error messages with full context

### 3. Created Deployment Script
Created `deploy_to_pi.sh` to streamline deployments:
- Pulls latest code from git
- Restarts the pi-assistant service
- Shows service status and recent logs
- Makes debugging and updates faster

## Verification
After deployment, the service restarted successfully and is now running on `http://0.0.0.0:8080`.

## Files Modified
- `pi-assistant/config.py` - Fixed model name
- `pi-assistant/ai_service.py` - Improved logging and error handling
- `deploy_to_pi.sh` - New deployment automation script

## Next Steps
- Test the chat functionality in the web UI
- Verify streaming responses work correctly
- Test with different conversation contexts
- Consider adding model selection UI if needed
