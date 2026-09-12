#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/DirectRelease"
APP_NAME="Genie"
BUNDLE_ID="com.nicholasdudek.genie"
DMG_OUTPUT="$PROJECT_DIR/Genie.dmg"
ZIP_OUTPUT="$PROJECT_DIR/Genie.zip"

echo "=============================================="
echo "  Packaging Genie for Direct Website Distribution"
echo "  (Developer ID / Hardened Runtime / Notarization)"
echo "=============================================="

# 1. Terminate running instances
echo "==> Terminating running Genie instances..."
killall Genie 2>/dev/null || true
killall GoldGate 2>/dev/null || true
sleep 0.5

# 2. Build Release binary with SwiftPM if not already present
cd "$PROJECT_DIR"
if [ ! -f "$PROJECT_DIR/.build/out/Products/Release/$APP_NAME" ] && [ ! -f "$PROJECT_DIR/.build/release/$APP_NAME" ]; then
    echo "==> Compiling Release binary with SwiftPM..."
    swift build -c release
else
    echo "==> Using existing Release binary..."
fi

# 3. Generate and compile Assets.xcassets (Asset Catalog)
if [ -f "$PROJECT_DIR/generate_asset_catalog.sh" ]; then
    echo "==> Compiling Asset Catalog..."
    ./generate_asset_catalog.sh
fi

# 4. Prepare Staging Bundle
echo "==> Preparing App Bundle Structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

BIN_PATH="$(swift build -c release --show-bin-path 2>/dev/null || true)"
if [ -n "$BIN_PATH" ] && [ -f "$BIN_PATH/$APP_NAME" ]; then
    cp "$BIN_PATH/$APP_NAME" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
elif [ -f "$PROJECT_DIR/.build/out/Products/Release/$APP_NAME" ]; then
    cp "$PROJECT_DIR/.build/out/Products/Release/$APP_NAME" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
elif [ -f "$PROJECT_DIR/.build/release/$APP_NAME" ]; then
    cp "$PROJECT_DIR/.build/release/$APP_NAME" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
else
    echo "Error: Cannot find compiled binary for $APP_NAME"
    exit 1
fi
cp "$PROJECT_DIR/Sources/GoldGate/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"

# Copy SwiftPM resource bundles (GenieEnvironmentKit ships the Linux guest worker).
# Bundle.module resolves these from Contents/Resources; without them the guest
# installer traps at runtime instead of reporting a normal error.
if [ -n "$BIN_PATH" ]; then
    for RESOURCE_BUNDLE in "$BIN_PATH"/*.bundle; do
        [ -d "$RESOURCE_BUNDLE" ] || continue
        cp -R "$RESOURCE_BUNDLE" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
    done
    # A local test run leaves __pycache__ beside the guest scripts, and SwiftPM
    # copies the directory verbatim. Don't ship one machine's stale bytecode.
    find "$BUILD_DIR/$APP_NAME.app/Contents/Resources" -name '__pycache__' -type d -prune -exec rm -rf {} +
fi

# Copy compiled Assets.car
if [ -f "$PROJECT_DIR/build/compiled_assets/Assets.car" ]; then
    cp "$PROJECT_DIR/build/compiled_assets/Assets.car" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/Assets.car"
fi
# Copy full-res AppIcon.icns
if [ -f "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
fi
if [ -d "$PROJECT_DIR/Wallpapers" ]; then
    cp -R "$PROJECT_DIR/Wallpapers" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi
if [ -f "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.png" ]; then
    cp "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.png" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi
if [ -d "$PROJECT_DIR/web" ]; then
    cp -R "$PROJECT_DIR/web" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi

# 5. Detect Signing Identity
echo "==> Detecting Signing Identity..."
if [ "$ADHOC" = "1" ]; then
    DEV_ID=""
elif [ -n "$SIGN_IDENTITY" ]; then
    DEV_ID="$SIGN_IDENTITY"
else
    DEV_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n 1 | awk '{print $2}' || true)
    if [ -z "$DEV_ID" ]; then
        DEV_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk '{print $2}' || true)
    fi
fi

echo "Using Signing Identity: ${DEV_ID:-Ad-Hoc / Self-Signed (-)}"

# Strip extended attributes and quarantine flags before codesigning
xattr -cr "$BUILD_DIR/$APP_NAME.app"

# 6. Sign nested bundles, binary, and app bundle.
ENTITLEMENTS="$PROJECT_DIR/Sources/GoldGate/Genie.entitlements"
if [ -n "$DEV_ID" ]; then
    echo "==> Code signing with identity ($DEV_ID)..."
    for NESTED_BUNDLE in "$BUILD_DIR/$APP_NAME.app/Contents/Resources"/*.bundle; do
        [ -d "$NESTED_BUNDLE" ] || continue
        codesign --force --sign "$DEV_ID" "$NESTED_BUNDLE"
    done
    codesign --force --entitlements "$ENTITLEMENTS" --sign "$DEV_ID" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --entitlements "$ENTITLEMENTS" --sign "$DEV_ID" "$BUILD_DIR/$APP_NAME.app"
else
    echo "==> Ad-Hoc code signing with entitlements..."
    for NESTED_BUNDLE in "$BUILD_DIR/$APP_NAME.app/Contents/Resources"/*.bundle; do
        [ -d "$NESTED_BUNDLE" ] || continue
        codesign --force --sign - "$NESTED_BUNDLE"
    done
    codesign --force --entitlements "$ENTITLEMENTS" --sign - "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --entitlements "$ENTITLEMENTS" --sign - "$BUILD_DIR/$APP_NAME.app"
fi

# 7. Create DMG for website distribution
echo "==> Building distributable Disk Image ($DMG_OUTPUT)..."
DMG_STAGE="$BUILD_DIR/dmg_stage"
rm -rf "$DMG_STAGE" "$DMG_OUTPUT" "$ZIP_OUTPUT"
mkdir -p "$DMG_STAGE"

cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
ln -s "/Applications/Utilities" "$DMG_STAGE/Utilities (Optional)" 2>/dev/null || true

xattr -rc "$DMG_STAGE" 2>/dev/null || true
sync
sleep 1

hdiutil create -volname "Genie Installer" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DMG_OUTPUT"

# Sign DMG if Developer ID is available
if [ -n "$DEV_ID" ]; then
    codesign --force --sign "$DEV_ID" "$DMG_OUTPUT"
fi

# Create Zip distribution archive as well
rm -f "$ZIP_OUTPUT"
cd "$BUILD_DIR"
zip -r -q -0 "$ZIP_OUTPUT" "$APP_NAME.app"
cd "$PROJECT_DIR"

echo "=============================================="
echo "  ✅ DIRECT DISTRIBUTION BUILD SUCCESSFUL!"
echo "  DMG Installer: $DMG_OUTPUT"
echo "  Zip Archive:   $ZIP_OUTPUT"
echo "=============================================="

# 8. Install to /Applications
echo "==> Updating /Applications/$APP_NAME.app..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$BUILD_DIR/$APP_NAME.app" "/Applications/$APP_NAME.app"
echo "==> Done!"
