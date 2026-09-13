#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_PATH="$PROJECT_DIR/Genie.pkg"
APPLE_ID="nicholas.dudek@icloud.com"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-@keychain:GENIE_ASC_PASSWORD}"  # stored via: xcrun altool --store-password-in-keychain-item GENIE_ASC_PASSWORD -u <apple-id> -p <app-specific-password>

echo "=============================================="
echo "  Uploading Genie to Apple App Store Connect"
echo "=============================================="

if [ ! -f "$PKG_PATH" ]; then
    echo "Re-packaging Genie.pkg..."
    "$PROJECT_DIR/package_for_app_store.sh"
fi

echo "==> Validating package with App Store Connect..."
if xcrun altool --validate-app -f "$PKG_PATH" -t osx -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD" 2>/dev/null; then
    echo "==> Sending package to App Store Connect..."
    xcrun altool --upload-app -f "$PKG_PATH" -t osx -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD"
    echo "=============================================="
    echo "  SUCCESS! Genie delivered to App Store Connect!"
    echo "=============================================="
else
    echo "==> Note: Command-line altool requires an App-Specific Password stored in Keychain."
    echo "    To configure for 1-step CLI uploads, run:"
    echo "    xcrun altool --store-password-in-keychain-item GENIE_ASC_PASSWORD -u $APPLE_ID -p <your-app-specific-password>"
    echo ""
    echo "==> Opening Apple Transporter with $PKG_PATH for instant 1-click delivery..."
    open -a Transporter "$PKG_PATH"
    echo "=============================================="
    echo "  Transporter is ready! Click 'Deliver' in Transporter to publish to App Store Connect."
    echo "=============================================="
fi
