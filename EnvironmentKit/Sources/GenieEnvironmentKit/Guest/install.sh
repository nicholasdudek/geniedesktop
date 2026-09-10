#!/bin/bash
# Run inside an Ubuntu/Debian Linux guest: sudo bash install.sh
# Works in a UTM VM or an OrbStack machine; the QEMU guest agent is installed
# only where the virtio port for it exists.
set -euo pipefail
if [[ $(uname -s) != Linux || $EUID != 0 ]]; then
    echo 'Run this installer as root INSIDE the Linux VM.' >&2
    exit 1
fi
source_dir=$(cd -- "$(dirname -- "$0")" && pwd)
apt-get update
apt-get install -y python3 python3-venv
guest_agent=''
if [[ -e /dev/virtio-ports/org.qemu.guest_agent.0 ]]; then
    guest_agent=qemu-guest-agent
    apt-get install -y qemu-guest-agent
fi
id genie-env >/dev/null 2>&1 || useradd --system --create-home --home-dir /var/lib/genie-environment --shell /usr/sbin/nologin genie-env
install -d -m 755 /opt/genie-environment
install -d -m 700 -o genie-env -g genie-env /var/lib/genie-environment
install -m 644 "$source_dir/worker.py" "$source_dir/client.py" /opt/genie-environment/
python3 -m venv /opt/genie-environment/venv
/opt/genie-environment/venv/bin/pip install 'playwright==1.58.0'

# Chromium's runtime libraries are installed directly: playwright install-deps
# resolves a per-release package list, and on a release it does not know it
# prints an error but still exits 0, so its result cannot be branched on.
apt-get install -y --no-install-recommends libasound2t64 libatk-bridge2.0-0t64 \
    libatk1.0-0t64 libatspi2.0-0t64 libcairo2 libcups2t64 libdbus-1-3 libdrm2 \
    libgbm1 libglib2.0-0t64 libnspr4 libnss3 libpango-1.0-0 libx11-6 libxcb1 \
    libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxrandr2 \
    libudev1 fonts-liberation

# Playwright refuses to download a browser for a release it does not recognise.
# The previous LTS build runs correctly on later releases, so retry with that.
platform_override=''
if ! runuser -u genie-env -- /opt/genie-environment/venv/bin/python -m playwright install chromium; then
    case $(dpkg --print-architecture) in
        arm64) platform_override=ubuntu24.04-arm64 ;;
        *) platform_override=ubuntu24.04-x64 ;;
    esac
    echo "Playwright does not support this release; retrying with $platform_override builds."
    runuser -u genie-env -- env PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="$platform_override" \
        /opt/genie-environment/venv/bin/python -m playwright install chromium
fi
# Large extracts have been lost to an abrupt guest shutdown; flush them now.
sync

cat > /etc/systemd/system/genie-environment.service <<'SERVICE'
[Unit]
Description=Genie durable environment worker
After=network.target

[Service]
User=genie-env
Group=genie-env
WorkingDirectory=/var/lib/genie-environment
ExecStart=/opt/genie-environment/venv/bin/python /opt/genie-environment/worker.py
Restart=on-failure
RestartSec=3
KillMode=control-group
TimeoutStopSec=15
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/genie-environment
MemoryMax=3G
CPUQuota=300%
TasksMax=512
LimitFSIZE=1073741824

[Install]
WantedBy=multi-user.target
SERVICE
# The worker resolves the browser through the same host check at launch.
if [[ -n $platform_override ]]; then
    sed -i "/^\[Service\]/a Environment=PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=$platform_override" /etc/systemd/system/genie-environment.service
fi
# The host reaches the bridge through this account without a password. The rule
# grants exactly one command, and nothing else, as the worker user.
client_user=${GENIE_ENV_CLIENT_USER:-${SUDO_USER:-}}
if [[ -n $client_user && $client_user != root ]]; then
    printf '%s ALL=(genie-env) NOPASSWD: /usr/bin/python3 /opt/genie-environment/client.py -\n' "$client_user" \
        > /etc/sudoers.d/genie-environment
    chmod 440 /etc/sudoers.d/genie-environment
    visudo -c -f /etc/sudoers.d/genie-environment
fi

systemctl daemon-reload
systemctl enable --now genie-environment.service
if [[ -n $guest_agent ]]; then
    systemctl start "$guest_agent"
fi
systemctl is-active genie-environment.service ${guest_agent:+$guest_agent}
echo 'Genie guest worker installed. Return to Genie and connect this environment.'
