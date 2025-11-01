#!/usr/bin/env python3
"""Test WebSocket chat functionality"""

import asyncio
import json
import websockets
import sys

async def test_chat():
    uri = "ws://localhost:8080/ws"
    
    print(f"🔌 Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ WebSocket connected!")
            
            # Send a test message
            message = {
                "type": "chat",
                "messages": [
                    {"role": "user", "content": "Say hello!"}
                ]
            }
            
            print(f"📤 Sending: {json.dumps(message)}")
            await websocket.send(json.dumps(message))
            
            print("📥 Waiting for responses...")
            
            # Receive responses
            response_count = 0
            full_response = ""
            
            while True:
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=30)
                    data = json.loads(response)
                    response_count += 1
                    
                    print(f"\n📨 Response #{response_count}: {data.get('type')}")
                    
                    if data.get('type') == 'chat_chunk':
                        content = data.get('content', '')
                        full_response += content
                        print(f"   Chunk: '{content}'")
                    
                    elif data.get('type') == 'chat_complete':
                        print(f"\n✅ Chat complete!")
                        print(f"Full response: {full_response}")
                        break
                    
                    elif data.get('type') == 'error':
                        print(f"\n❌ Error: {data.get('message')}")
                        break
                    
                except asyncio.TimeoutError:
                    print("\n⏱️  Timeout waiting for response")
                    break
            
            print(f"\n📊 Total responses: {response_count}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(test_chat())
