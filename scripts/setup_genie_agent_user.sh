#!/bin/bash
# ==============================================================================
# setup_genie_agent_user.sh
# 
# Provisions a dedicated macOS user account ('genie-agent') and shared workspace
# directories (/Users/Shared/Genie/spaces) for concurrent multi-user execution.
#
# Allows Genie 3.0 agents to execute in an isolated environment with separate
# PATH, permissions, and background process tree without interfering with the
# primary user's desktop sessions or tools.
# ==============================================================================

set -e

AGENT_USER="genie-agent"
AGENT_FULLNAME="Genie Autonomous Agent"
SHARED_ROOT="/Users/Shared/Genie"
SPACES_DIR="${SHARED_ROOT}/spaces"

echo "🤖 Genie 3.0 Multi-User Setup"
echo "=============================="

# 1. Create Shared Workspace Infrastructure
echo "📁 Setting up shared workspace directory at: ${SPACES_DIR}"
sudo mkdir -p "${SPACES_DIR}"
sudo chmod -R 777 "${SHARED_ROOT}"

# 2. Check or Create 'genie-agent' macOS Account
if id -u "${AGENT_USER}" >/dev/null 2>&1; then
    echo "✅ macOS user account '${AGENT_USER}' already exists."
else
    echo "👤 Creating dedicated macOS user account '${AGENT_USER}'..."
    sudo sysadminctl -addUser "${AGENT_USER}" \
        -fullName "${AGENT_FULLNAME}" \
        -home "/Users/${AGENT_USER}" \
        -shell "/bin/zsh"
    echo "✅ Created macOS user '${AGENT_USER}'."
fi

# 3. Ensure Agent Home & Workspace Permissions
if [ -d "/Users/${AGENT_USER}" ]; then
    echo "🔒 Configuring '${AGENT_USER}' workspace permissions..."
    sudo mkdir -p "/Users/${AGENT_USER}/.genie/spaces"
    sudo chown -R "${AGENT_USER}:staff" "/Users/${AGENT_USER}/.genie" 2>/dev/null || true
fi

# 4. Configure Headless / Background Execution Tips
echo ""
echo "🚀 Multi-User Execution Capabilities Enabled:"
echo "------------------------------------------------"
echo "1. Headless Background Execution:"
echo "   Agents can run isolated tasks via:"
echo "   sudo -u ${AGENT_USER} /bin/zsh -c '<command>'"
echo ""
echo "2. Dedicated Headless Screen / Virtual Display:"
echo "   Using macOS Screen Sharing, you can connect to the agent session:"
echo "   open vnc://${AGENT_USER}@localhost"
echo "   This enables full GUI automation without taking over your mouse or keyboard!"
echo ""
echo "3. Shared Workspace:"
echo "   Both users have unrestricted read/write access to:"
echo "   ${SPACES_DIR}"
echo "================================================"
echo "✨ Genie Agent multi-user setup complete."
