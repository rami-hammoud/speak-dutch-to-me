#!/usr/bin/env bash
# Cleanup script to remove v4l2loopback virtual camera setup
# Run this on your Pi to remove choppy camera performance issues

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Virtual Camera Cleanup Script             ║${NC}"
echo -e "${GREEN}║  Removing v4l2loopback for better camera   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

log "Checking for v4l2loopback..."

# Check if module is loaded
if lsmod | grep -q v4l2loopback; then
    log "Unloading v4l2loopback kernel module..."
    sudo modprobe -r v4l2loopback || warn "Failed to unload module"
    success "Module unloaded"
else
    log "Module not currently loaded"
fi

# Remove boot configuration
if [ -f /etc/modules-load.d/v4l2loopback.conf ]; then
    log "Removing boot configuration..."
    sudo rm /etc/modules-load.d/v4l2loopback.conf
    success "Boot configuration removed"
fi

if [ -f /etc/modprobe.d/v4l2loopback.conf ]; then
    log "Removing module options..."
    sudo rm /etc/modprobe.d/v4l2loopback.conf
    success "Module options removed"
fi

# Optionally remove the package
read -p "Do you want to uninstall v4l2loopback packages? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing v4l2loopback packages..."
    sudo apt remove -y v4l2loopback-dkms v4l2loopback-utils || warn "Package removal failed"
    sudo apt autoremove -y
    success "Packages removed"
fi

echo ""
success "✨ Virtual camera cleanup complete!"
echo ""
warn "⚠️  Reboot recommended to ensure all changes take effect:"
echo "    sudo reboot"
echo ""
