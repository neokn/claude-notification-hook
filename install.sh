#!/bin/bash
set -e

# Pulse Notify Installer (macOS Apple Silicon only)
# Usage: curl -fsSL https://raw.githubusercontent.com/neokn/claude-notification-hook/main/install.sh | bash

REPO="neokn/claude-notification-hook"
INSTALL_DIR="$HOME/.claude/hooks/claude-notification-hook"
BIN_DIR="$INSTALL_DIR/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check platform
check_platform() {
    if [ "$(uname -s)" != "Darwin" ]; then
        error "This installer only supports macOS"
    fi
    
    if [ "$(uname -m)" != "arm64" ]; then
        error "This installer only supports Apple Silicon (M1/M2/M3/M4)"
    fi
    
    info "Platform: macOS Apple Silicon ✓"
}

# Get latest release version
get_latest_version() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Download and install
install() {
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║       Pulse Notify Installer           ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    check_platform
    
    local version
    version=$(get_latest_version)
    if [ -z "$version" ]; then
        error "Failed to get latest version. Check: https://github.com/${REPO}/releases"
    fi
    info "Latest version: ${version}"
    
    info "Creating directory: ${INSTALL_DIR}"
    mkdir -p "$BIN_DIR"
    
    info "Downloading binary..."
    download_url="https://github.com/${REPO}/releases/download/${version}/pulse-notify"
    if ! curl -fsSL "$download_url" -o "${BIN_DIR}/pulse-notify"; then
        error "Failed to download: ${download_url}"
    fi
    chmod +x "${BIN_DIR}/pulse-notify"
    info "Installed: ${BIN_DIR}/pulse-notify"
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
    echo ""
    echo -e "${BOLD}Add to ~/.claude/settings.json:${NC}"
    echo ""
    echo -e "${CYAN}"
    cat << 'JSONEOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c red -s Ping" }]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c blue -s Blow" }]
      },
      {
        "matcher": "elicitation_dialog",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c purple -s Pop" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c orange -s Glass" }]
      }
    ]
  }
}
JSONEOF
    echo -e "${NC}"
    echo -e "${BOLD}Test it:${NC}"
    echo "  ${BIN_DIR}/pulse-notify -c green -d 3"
    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo "  https://github.com/${REPO}"
    echo ""
}

install
