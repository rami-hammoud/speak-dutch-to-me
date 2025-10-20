#!/usr/bin/env bash
# Virtual Camera Setup for Zoom/Video Conferencing
# Creates a flipped virtual camera device that persists across reboots
set -euo pipefail

log() { echo -e "[VirtualCam] $*"; }
warn() { echo -e "[VirtualCam][WARN] $*"; }
err() { echo -e "[VirtualCam][ERROR] $*" 1>&2; }

if [[ $(id -u) -eq 0 ]]; then
  err "Don't run this script as root. Run as normal user, sudo will be used when needed."
  exit 1
fi

log "=== Virtual Camera Setup for Raspberry Pi ==="
log "This will create a virtual camera device that Zoom can use"
log "Camera will be automatically flipped and available at /dev/video10"
echo

# Install required packages
log "Installing required packages..."
sudo apt update
sudo apt install -y \
  v4l2loopback-dkms \
  v4l2loopback-utils \
  ffmpeg \
  libcamera-apps

# Load v4l2loopback kernel module
log "Loading v4l2loopback kernel module..."
sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam" exclusive_caps=1

# Verify the module loaded
if [[ ! -e /dev/video10 ]]; then
  err "Failed to create /dev/video10. Check dmesg for errors."
  exit 1
fi
log "✓ Virtual camera device created at /dev/video10"

# Make it load on boot
log "Configuring module to load on boot..."
if ! grep -q "^v4l2loopback" /etc/modules 2>/dev/null; then
  echo "v4l2loopback" | sudo tee -a /etc/modules >/dev/null
fi

sudo mkdir -p /etc/modprobe.d
cat <<'EOF' | sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
# Virtual camera for Zoom/video conferencing
options v4l2loopback devices=1 video_nr=10 card_label="PiAssistantCam" exclusive_caps=1
EOF
log "✓ Module configured to load on boot"

# Create the streaming script
log "Creating camera streaming script..."
sudo tee /usr/local/bin/stream-to-virtual-cam.sh >/dev/null <<'SCRIPT_EOF'
#!/usr/bin/env bash
# Stream Pi Camera to virtual device with flip
set -euo pipefail

# Configuration
VFLIP="--vflip"    # Remove to disable vertical flip
HFLIP="--hflip"    # Remove to disable horizontal flip
WIDTH=640
HEIGHT=480
FPS=30
OUTPUT_DEV=/dev/video10

# Wait for camera to be ready
sleep 3

# Stream from Pi Camera to virtual device
# Using rpicam-vid (new command) or libcamera-vid (old command)
if command -v rpicam-vid >/dev/null 2>&1; then
  exec rpicam-vid \
    -t 0 \
    --width $WIDTH \
    --height $HEIGHT \
    --framerate $FPS \
    $VFLIP \
    $HFLIP \
    -n \
    --codec yuv420 \
    -o - | \
  ffmpeg -f rawvideo \
    -pix_fmt yuv420p \
    -s ${WIDTH}x${HEIGHT} \
    -r $FPS \
    -i - \
    -f v4l2 \
    -pix_fmt yuv420p \
    $OUTPUT_DEV
else
  exec libcamera-vid \
    -t 0 \
    --width $WIDTH \
    --height $HEIGHT \
    --framerate $FPS \
    $VFLIP \
    $HFLIP \
    -n \
    --codec yuv420 \
    -o - | \
  ffmpeg -f rawvideo \
    -pix_fmt yuv420p \
    -s ${WIDTH}x${HEIGHT} \
    -r $FPS \
    -i - \
    -f v4l2 \
    -pix_fmt yuv420p \
    $OUTPUT_DEV
fi
SCRIPT_EOF

sudo chmod +x /usr/local/bin/stream-to-virtual-cam.sh
log "✓ Streaming script created"

# Create systemd service
log "Creating systemd service..."
sudo tee /etc/systemd/system/virtual-camera.service >/dev/null <<'SERVICE_EOF'
[Unit]
Description=Virtual Camera Stream for Zoom
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
ExecStartPre=/bin/sleep 5
ExecStart=/usr/local/bin/stream-to-virtual-cam.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

log "✓ Systemd service created"

# Enable and start the service
log "Enabling virtual camera service..."
sudo systemctl daemon-reload
sudo systemctl enable virtual-camera.service
log "✓ Service enabled (will start on boot)"

# Ask user if they want to start now
read -r -p "Start the virtual camera service now? [Y/n]: " START_NOW
if [[ ! "${START_NOW:-}" =~ ^[Nn]$ ]]; then
  log "Starting service..."
  sudo systemctl start virtual-camera.service
  sleep 3
  
  # Check status
  if sudo systemctl is-active --quiet virtual-camera.service; then
    log "✓ Service is running"
  else
    warn "Service may have issues. Check status with:"
    warn "  sudo systemctl status virtual-camera.service"
    warn "  sudo journalctl -u virtual-camera.service -f"
  fi
fi

# Test the virtual camera
log ""
log "Testing virtual camera device..."
if v4l2-ctl --device=/dev/video10 --all >/dev/null 2>&1; then
  log "✓ Virtual camera is accessible"
  v4l2-ctl --device=/dev/video10 --list-formats-ext | head -20
else
  warn "Could not access /dev/video10. May need to wait for service to start."
fi

# Summary
log ""
log "=== Setup Complete ==="
log "Virtual camera device: /dev/video10"
log "Device name in Zoom: PiAssistantCam"
log "Camera orientation: Flipped (both horizontal and vertical)"
log ""
log "To customize flip settings, edit:"
log "  /usr/local/bin/stream-to-virtual-cam.sh"
log "  (Remove VFLIP or HFLIP lines to disable flipping)"
log ""
log "Service management:"
log "  Start:   sudo systemctl start virtual-camera.service"
log "  Stop:    sudo systemctl stop virtual-camera.service"
log "  Status:  sudo systemctl status virtual-camera.service"
log "  Logs:    sudo journalctl -u virtual-camera.service -f"
log ""
log "In Zoom:"
log "  1. Open Settings → Video"
log "  2. Select 'PiAssistantCam' from camera dropdown"
log "  3. Your flipped Pi Camera feed should appear"
log ""
log "Done!"

exit 0
