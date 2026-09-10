#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/AppStore"
APP_NAME="Genie"
BUNDLE_ID="com.nicholasdudek.genie"
PKG_OUTPUT="$PROJECT_DIR/Genie.pkg"

echo "=============================================="
echo "  Packaging & Code Signing: $APP_NAME for Mac App Store"
echo "=============================================="

# 1. Terminate running instances to prevent code signing SIGKILL conflicts
echo "==> Ensuring no previous Genie or Gold Gate instance is active..."
killall Genie 2>/dev/null || true
killall GoldGate 2>/dev/null || true
killall "Gold Gate" 2>/dev/null || true
killall "Golden Gate Studio" 2>/dev/null || true
sleep 0.5

# 2. Build Release binary — Genie Lite flavour
#
# GENIE_MAS=1 compiles out every subsystem the sandbox or the App Store Review
# Guidelines forbid (see GenieCapabilities.swift). It builds into its own
# scratch directory: the Developer ID build differs only by a compile-time
# define, so a shared .build would silently hand us the wrong binary.
cd "$PROJECT_DIR"
MAS_BUILD_DIR="$PROJECT_DIR/.build-mas"
echo "==> Building Release executable with SwiftPM (Genie Lite / GENIE_MAS)..."
GENIE_MAS=1 swift build -c release -j 4 --scratch-path "$MAS_BUILD_DIR"

# 3. Generate and compile Assets.xcassets (Asset Catalog)
echo "==> Compiling Asset Catalog..."
./generate_asset_catalog.sh

# 4. Prepare staging bundle
echo "==> Preparing App Bundle Structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

GENIE_BINARY=""
for candidate in \
    "$MAS_BUILD_DIR/release/Genie" \
    "$MAS_BUILD_DIR/out/Products/Release/Genie"; do
    if [ -f "$candidate" ]; then GENIE_BINARY="$candidate"; break; fi
done

if [ -z "$GENIE_BINARY" ]; then
    echo "ERROR: no Genie binary produced in $MAS_BUILD_DIR." >&2
    exit 1
fi

# Refuse to package a Developer ID binary as the App Store build. Without this
# the mistake is invisible until App Review rejects the submission.
if ! strings "$GENIE_BINARY" | grep -q "GENIE-BUILD-FLAVOUR:MAS"; then
    echo "ERROR: $GENIE_BINARY is not a Genie Lite build." >&2
    echo "       Expected marker GENIE-BUILD-FLAVOUR:MAS (set GENIE_MAS=1)." >&2
    exit 1
fi
echo "==> Verified Genie Lite build marker."
cp "$GENIE_BINARY" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/Genie"
cp "$PROJECT_DIR/Sources/GoldGate/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :NSSystemAdministrationUsageDescription" "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist" 2>/dev/null || true

# Copy compiled Assets.car
if [ -f "$PROJECT_DIR/build/compiled_assets/Assets.car" ]; then
    cp "$PROJECT_DIR/build/compiled_assets/Assets.car" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/Assets.car"
    echo "==> Included Assets.car in Genie.app bundle"
fi
# Always use the original high-res AppIcon.icns (actool generates a low-res 256px version)
if [ -f "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
    echo "==> Included full-res AppIcon.icns (1024px) in Genie.app bundle"
fi

if [ -d "$PROJECT_DIR/Wallpapers" ]; then
    cp -R "$PROJECT_DIR/Wallpapers" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi

if [ -f "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.png" ]; then
    cp "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.png" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi
if [ -f "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.jpg" ]; then
    cp "$PROJECT_DIR/Sources/GoldGate/HeaderBadge.jpg" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
fi

# 5. Detect Signing Identity SHA-1 Fingerprint
echo "==> Detecting Signing Identity Fingerprint..."
APP_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -n 1 | awk '{print $2}' || true)
if [ -z "$APP_IDENTITY" ]; then
    APP_IDENTITY=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Application" | head -n 1 | awk '{print $2}' || true)
fi
if [ -z "$APP_IDENTITY" ]; then
    APP_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk '{print $2}' || true)
fi

INSTALLER_IDENTITY=$(security find-identity -v | grep "Mac Installer Distribution" | head -n 1 | awk '{print $2}' || true)
if [ -z "$INSTALLER_IDENTITY" ]; then
    INSTALLER_IDENTITY=$(security find-identity -v | grep "3rd Party Mac Developer Installer" | head -n 1 | awk '{print $2}' || true)
fi

echo "Using App Signing Identity SHA-1: ${APP_IDENTITY:-Self-Signed/Ad-Hoc}"
echo "Using Installer Signing Identity SHA-1: ${INSTALLER_IDENTITY:-None}"

# 6. Embed provisioning profile (fixes ITMS-90889: Missing provisioning profile for TestFlight)
echo "==> Looking for Mac App Store provisioning profile for $BUNDLE_ID..."
PROVISION_PROFILE=""
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILES_DIR" ]; then
    for profile in "$PROFILES_DIR"/*.provisionprofile "$PROFILES_DIR"/*.mobileprovision; do
        [ -f "$profile" ] || continue
        PROFILE_APP_ID=$(security cms -D -i "$profile" 2>/dev/null | \
            /usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.application-identifier" /dev/stdin 2>/dev/null || \
            security cms -D -i "$profile" 2>/dev/null | \
            /usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /dev/stdin 2>/dev/null || true)
        # Strip team prefix (e.g. "TEAMID.com.nicholasdudek.genie" → "com.nicholasdudek.genie")
        PROFILE_BUNDLE_ID=$(echo "$PROFILE_APP_ID" | sed 's/^[A-Z0-9]*\.//')
        if [ "$PROFILE_BUNDLE_ID" = "$BUNDLE_ID" ]; then
            PROVISION_PROFILE="$profile"
            echo "==> Found matching provisioning profile: $(basename "$profile")"
            break
        fi
    done
fi

if [ -n "$PROVISION_PROFILE" ]; then
    cp "$PROVISION_PROFILE" "$BUILD_DIR/$APP_NAME.app/Contents/embedded.provisionprofile"
    echo "==> Provisioning profile embedded into bundle."
else
    echo "==> WARNING: No matching provisioning profile found for $BUNDLE_ID."
    echo "    To fix ITMS-90889 (required for TestFlight):"
    echo "    1. Go to: https://developer.apple.com/account/resources/profiles/list"
    echo "    2. Download the Mac App Store profile for $BUNDLE_ID"
    echo "    3. Double-click it to install, then re-run this script"
fi

# 7. Sign the App Bundle
if [ -n "$APP_IDENTITY" ]; then
    echo "==> Code signing inner executable..."
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign "$APP_IDENTITY" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    echo "==> Code signing App Bundle with Hardened Runtime & Sandbox entitlements..."
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign "$APP_IDENTITY" "$BUILD_DIR/$APP_NAME.app"
else
    echo "==> Ad-Hoc code signing App Bundle..."
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign - "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign - "$BUILD_DIR/$APP_NAME.app"
fi

# 7b. Verify the signature actually carries the sandbox entitlement.
echo "==> Verifying sandbox entitlement on the signed bundle..."
if codesign -d --entitlements :- "$BUILD_DIR/$APP_NAME.app" 2>/dev/null | \
   grep -A1 "com.apple.security.app-sandbox" | grep -q "<true/>"; then
    echo "==> app-sandbox: enabled."
else
    echo "ERROR: signed bundle is not sandboxed — App Store will reject it." >&2
    exit 1
fi

# 8. Build Installer Package (.pkg) for App Store Connect
echo "==> Generating App Store .pkg installer package..."
if [ -n "$INSTALLER_IDENTITY" ]; then
    productbuild --component "$BUILD_DIR/$APP_NAME.app" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_OUTPUT"
else
    productbuild --component "$BUILD_DIR/$APP_NAME.app" /Applications "$PKG_OUTPUT"
fi

echo "=============================================="
echo "  SUCCESS! App Store Package Created at:"
echo "  $PKG_OUTPUT"
echo "=============================================="

# 9. Install to /Applications
echo "==> Installing $APP_NAME.app to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$BUILD_DIR/$APP_NAME.app" "/Applications/$APP_NAME.app"

# 10. Create Desktop and Home Folder Installation Shortcuts & clean legacy
echo "==> Creating Desktop & Home Folder Application Shortcuts..."
rm -f "$HOME/Desktop/Golden Gate Studio.app" "$HOME/Desktop/Gold Gate.app"
rm -f "$HOME/Golden Gate Studio.app" "$HOME/Gold Gate.app"
ln -sfn "/Applications/$APP_NAME.app" "$HOME/Desktop/$APP_NAME.app" 2>/dev/null || true
ln -sfn "/Applications/$APP_NAME.app" "$HOME/$APP_NAME.app" 2>/dev/null || true
echo "==> Application installed to /Applications/$APP_NAME.app and shortcuts updated."
