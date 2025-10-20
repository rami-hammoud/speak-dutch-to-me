#!/usr/bin/env bash
# Quick utility to manage the virtual camera service
set -euo pipefail

SERVICE="virtual-camera.service"

case "${1:-}" in
  start)
    echo "Starting virtual camera service..."
    sudo systemctl start "$SERVICE"
    sleep 2
    sudo systemctl status "$SERVICE" --no-pager
    ;;
  stop)
    echo "Stopping virtual camera service..."
    sudo systemctl stop "$SERVICE"
    ;;
  restart)
    echo "Restarting virtual camera service..."
    sudo systemctl restart "$SERVICE"
    sleep 2
    sudo systemctl status "$SERVICE" --no-pager
    ;;
  status)
    sudo systemctl status "$SERVICE" --no-pager
    ;;
  logs)
    echo "Showing logs (Ctrl+C to exit)..."
    sudo journalctl -u "$SERVICE" -f
    ;;
  enable)
    echo "Enabling virtual camera service (start on boot)..."
    sudo systemctl enable "$SERVICE"
    ;;
  disable)
    echo "Disabling virtual camera service (don't start on boot)..."
    sudo systemctl disable "$SERVICE"
    ;;
  test)
    echo "Testing virtual camera device..."
    if [[ -e /dev/video10 ]]; then
      echo "✓ Virtual camera device exists: /dev/video10"
      v4l2-ctl --device=/dev/video10 --all | head -20
    else
      echo "✗ Virtual camera device not found at /dev/video10"
      echo "Run ./setup_virtual_camera.sh first"
      exit 1
    fi
    ;;
  edit)
    echo "Opening streaming script for editing..."
    sudo ${EDITOR:-nano} /usr/local/bin/stream-to-virtual-cam.sh
    echo "Restart the service to apply changes: $0 restart"
    ;;
  *)
    echo "Virtual Camera Service Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start    - Start the virtual camera service"
    echo "  stop     - Stop the virtual camera service"
    echo "  restart  - Restart the virtual camera service"
    echo "  status   - Show service status"
    echo "  logs     - Show live logs (Ctrl+C to exit)"
    echo "  enable   - Enable service on boot"
    echo "  disable  - Disable service on boot"
    echo "  test     - Test if virtual camera device exists"
    echo "  edit     - Edit flip settings in streaming script"
    echo ""
    echo "Virtual camera device: /dev/video10"
    echo "Service name: $SERVICE"
    exit 1
    ;;
esac
