#!/bin/bash
set -e

# setup_osworld_vm.sh
# -------------------------------------------------------------
# Configures a Linux / Ubuntu VM or Docker container for OSWorld
# and Genie OS-level autonomous agent training and execution.
# -------------------------------------------------------------

echo "=========================================================="
echo " [Genie / OSWorld] Configuring Virtual Machine Environment "
echo "=========================================================="

# 1. Update and install input injection and display tools
echo "[1/4] Installing GUI input injection & display utilities..."
sudo apt-get update && sudo apt-get install -y \
    xvfb \
    xdotool \
    x11-utils \
    scrot \
    python3-pyautogui \
    python3-pip \
    jq

# 2. Configure and activate virtual display server
echo "[2/4] Initializing Xvfb virtual display server (:99)..."
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :99 -screen 0 1920x1080x24 &
    echo "Xvfb started on display :99"
else
    echo "Xvfb display server is already running."
fi

export DISPLAY=:99
if ! grep -q "export DISPLAY=:99" ~/.bashrc 2>/dev/null; then
    echo "export DISPLAY=:99" >> ~/.bashrc
fi

# 3. Expose tool schemas at /etc/agent_tools.json for dynamic runtime introspection
echo "[3/4] Exposing tool schemas at /etc/agent_tools.json..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SCHEMA_FILE="$REPO_DIR/Consolidated_Training/shadow_api_tools.json"

if [ -f "$SCHEMA_FILE" ]; then
    sudo cp "$SCHEMA_FILE" /etc/agent_tools.json
    sudo chmod 644 /etc/agent_tools.json
    echo "Successfully installed /etc/agent_tools.json ($(jq '. | length' /etc/agent_tools.json) tools)"
else
    echo "Warning: Schema file not found at $SCHEMA_FILE"
fi

# 4. Verify system environment
echo "[4/4] Verifying OSWorld VM Agent environment..."
echo " - DISPLAY: $DISPLAY"
echo " - xdotool: $(which xdotool)"
echo " - scrot:   $(which scrot)"
echo " - Tools Schema: /etc/agent_tools.json"

echo "=========================================================="
echo " [Genie / OSWorld] VM Environment Ready for Agent Training"
echo "=========================================================="
