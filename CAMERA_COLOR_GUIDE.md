# 📷 Camera Color & White Balance Guide

## What Was Fixed

Your white jacket was appearing orange/yellow because the camera's **white balance** wasn't properly configured. The camera was treating warm indoor lighting as the "neutral" color, making whites appear orange.

## Auto White Balance (AWB) Modes

The camera now automatically adjusts colors based on the lighting. You can change the AWB mode in `config.py`:

```python
CAMERA_AWB_MODE: int = 0  # Change this number
```

### Available Modes:

| Mode | Value | Best For | Description |
|------|-------|----------|-------------|
| **Auto** | 0 | General use | Camera auto-detects lighting (default) |
| **Tungsten** | 1 | Warm bulbs | Traditional yellow/warm light bulbs |
| **Fluorescent** | 2 | Office lights | Cool white fluorescent tubes |
| **Indoor** | 3 | Inside | General indoor lighting |
| **Daylight** | 4 | Natural light | Near windows, outdoor lighting |
| **Cloudy** | 5 | Overcast | Cloudy outdoor conditions |

## Current Configuration

```python
# From config.py (line 42)
CAMERA_AWB_MODE: int = 0  # Currently set to Auto
```

## How to Change AWB Mode

### Option 1: Edit Config (Permanent)

1. Edit `pi-assistant/config.py`
2. Change `CAMERA_AWB_MODE` value
3. Commit and push:
   ```bash
   git add pi-assistant/config.py
   git commit -m "Adjust camera white balance mode"
   git push
   ```
4. On the Pi:
   ```bash
   cd ~/workspace/speak-dutch-to-me
   git pull
   sudo systemctl restart pi-assistant
   ```

### Option 2: Quick Test (Temporary)

SSH to the Pi and test different modes:

```bash
# SSH to Pi
ssh voice-assistant

# Edit config temporarily
nano ~/workspace/speak-dutch-to-me/pi-assistant/config.py
# Change CAMERA_AWB_MODE value

# Restart service
sudo systemctl restart pi-assistant

# Check the camera - does it look better?
```

## Recommended Settings for Your Setup

Based on your image showing warm indoor lighting with a desk lamp:

### Try These (in order):
1. **Mode 0 (Auto)** - Let camera figure it out (current)
2. **Mode 4 (Daylight)** - If your lamp is bright/cool white
3. **Mode 1 (Tungsten)** - If using warm yellow bulbs
4. **Mode 3 (Indoor)** - General indoor compromise

## What Else Was Configured

The camera now also sets:
- **Brightness**: 0.0 (neutral, not too bright/dark)
- **Contrast**: 1.0 (normal, not enhanced)
- **Saturation**: 1.0 (normal colors, not oversaturated)
- **Auto Exposure**: Enabled (adjusts to lighting)

## Testing Tips

1. **Wait a few seconds** after service restart - AWB needs time to adjust
2. **Move around** - Point camera at different things (white paper, your face, the room)
3. **Check under your lighting** - The camera will adjust to whatever light is dominant
4. **Compare modes** - Try 2-3 different AWB modes to see which looks best

## Verification

Check the logs to confirm AWB is working:

```bash
ssh voice-assistant
sudo journalctl -u pi-assistant -n 20 --no-pager | grep AWB
```

You should see:
```
Camera controls set: AWB mode=auto, neutral color settings
```

## Troubleshooting

### Colors still look off?

1. **Try different AWB mode** - Your lighting might need a specific mode
2. **Check your lights** - Mixed lighting (window + lamp) can confuse AWB
3. **Give it time** - AWB takes 2-3 seconds to stabilize after changes
4. **Restart camera** - Sometimes helps: `sudo systemctl restart pi-assistant`

### Want more manual control?

You can add more advanced controls to the camera manager if needed:
- Manual white balance (set specific color temperature)
- Color correction matrix
- Gamma adjustments
- Sharpness/denoise settings

## Quick Reference

```bash
# Deploy white balance changes
cd ~/workspace/speak-dutch-to-me
git add pi-assistant/config.py
git commit -m "Update camera AWB mode"
git push

# On Pi
ssh voice-assistant
cd ~/workspace/speak-dutch-to-me
git pull
sudo systemctl restart pi-assistant

# Verify
sudo journalctl -u pi-assistant -n 10 --no-pager | grep AWB
```

## Current Status

✅ **AWB Enabled**: Auto white balance is active  
✅ **Mode**: Auto (mode 0)  
✅ **Deployed**: Running on Pi since Nov 1, 19:03 CET  
✅ **Warm-up**: 3 seconds for AWB to adjust  

Your camera should now show more accurate colors! 🎨
