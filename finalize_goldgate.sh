#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Genie"
BUNDLE_ID="com.nicholasdudek.genie"
BUILD_ROOT="$PROJECT_DIR/build"
DIRECT_BUILD_DIR="$BUILD_ROOT/DirectRelease"
APPSTORE_BUILD_DIR="$BUILD_ROOT/AppStore"
ASSETS_DIR="$BUILD_ROOT/compiled_assets"
DMG_OUTPUT="$PROJECT_DIR/Genie.dmg"
ZIP_OUTPUT="$PROJECT_DIR/Genie.zip"
PKG_OUTPUT="$PROJECT_DIR/Genie.pkg"

echo "=========================================================="
echo "  FINALIZING GOLD GATE / GENIE"
echo "  Location: $PROJECT_DIR"
echo "=========================================================="

# 1. Terminate running instances
echo "==> [1/7] Ensuring no running instances interfere..."
killall Genie 2>/dev/null || true
killall GoldGate 2>/dev/null || true
sleep 0.5

# 2. Compile Asset Catalog
echo "==> [2/7] Compiling Asset Catalog..."
if [ -f "$PROJECT_DIR/generate_asset_catalog.sh" ]; then
    "$PROJECT_DIR/generate_asset_catalog.sh"
fi
mkdir -p "$ASSETS_DIR"
if [ -d "$PROJECT_DIR/Sources/GoldGate/Assets.xcassets" ]; then
    actool "$PROJECT_DIR/Sources/GoldGate/Assets.xcassets" \
      --compile "$ASSETS_DIR" \
      --platform macosx \
      --minimum-deployment-target 14.0 \
      --app-icon AppIcon \
      --output-partial-info-plist "$ASSETS_DIR/assetcatalog_generated_info.plist"
fi

# 3. Build BOTH distribution flavours
#
# Genie ships two builds from one codebase, and they are NOT interchangeable:
#
#   Developer ID  — not sandboxed, full feature set.
#   Genie Lite    — GENIE_MAS=1, sandboxed; GenieCapabilities compiles out every
#                   subsystem the sandbox or App Review forbids.
#
# They differ only by a compile-time define, so each gets its own scratch
# directory. Assembling one binary into both bundles — which this script used to
# do — ships the unsandboxed build to App Review and gets it rejected.
echo "==> [3/7] Building both distribution flavours..."
cd "$PROJECT_DIR"

DEVID_SCRATCH="$PROJECT_DIR/.build"
MAS_SCRATCH="$PROJECT_DIR/.build-mas"

echo "    - Developer ID (full)..."
swift build -c release -Xswiftc -num-threads -Xswiftc 2 -j 2 --scratch-path "$DEVID_SCRATCH"

echo "    - Genie Lite (Mac App Store, sandboxed)..."
GENIE_MAS=1 swift build -c release -Xswiftc -num-threads -Xswiftc 2 -j 2 --scratch-path "$MAS_SCRATCH"

# locate_binary <scratch-path> -> echoes the built executable
locate_binary() {
    local scratch="$1"
    for candidate in \
        "$scratch/out/Products/Release/$APP_NAME" \
        "$scratch/release/$APP_NAME"; do
        if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
    done
    return 1
}

# require_marker <binary> <expected-marker>
require_marker() {
    local binary="$1" expected="$2"
    if ! strings "$binary" | grep -q "$expected"; then
        echo "ERROR: $binary does not carry $expected." >&2
        echo "       The wrong flavour was built — refusing to package it." >&2
        exit 1
    fi
}

DEVID_BIN="$(locate_binary "$DEVID_SCRATCH")" || { echo "ERROR: Developer ID binary not found!" >&2; exit 1; }
MAS_BIN="$(locate_binary "$MAS_SCRATCH")"     || { echo "ERROR: Genie Lite binary not found!" >&2; exit 1; }

require_marker "$DEVID_BIN" "GENIE-BUILD-FLAVOUR:DEVELOPER-ID"
require_marker "$MAS_BIN"   "GENIE-BUILD-FLAVOUR:MAS"

echo "Developer ID binary: $DEVID_BIN ($(du -h "$DEVID_BIN" | awk '{print $1}'))"
echo "Genie Lite binary:   $MAS_BIN ($(du -h "$MAS_BIN" | awk '{print $1}'))"

# 4. Helper function to populate App Bundle
assemble_bundle() {
    local target_bundle="$1"
    local source_binary="$2"
    echo "Assembling bundle: $target_bundle"
    echo "  from binary:     $source_binary"
    rm -rf "$target_bundle"
    mkdir -p "$target_bundle/Contents/MacOS"
    mkdir -p "$target_bundle/Contents/Resources"
    
    # Executable
    cp "$source_binary" "$target_bundle/Contents/MacOS/$APP_NAME"
    chmod +x "$target_bundle/Contents/MacOS/$APP_NAME"
    
    # Info.plist
    cp "$PROJECT_DIR/Sources/GoldGate/Info.plist" "$target_bundle/Contents/Info.plist"
    
    # AppIcon.icns (prefer native 1024px)
    if [ -f "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" ]; then
        cp "$PROJECT_DIR/Sources/GoldGate/AppIcon.icns" "$target_bundle/Contents/Resources/AppIcon.icns"
    elif [ -f "$ASSETS_DIR/AppIcon.icns" ]; then
        cp "$ASSETS_DIR/AppIcon.icns" "$target_bundle/Contents/Resources/AppIcon.icns"
    fi
    
    # Assets.car
    if [ -f "$ASSETS_DIR/Assets.car" ]; then
        cp "$ASSETS_DIR/Assets.car" "$target_bundle/Contents/Resources/Assets.car"
    fi
    
    # Wallpapers
    if [ -d "$PROJECT_DIR/Wallpapers" ]; then
        cp -R "$PROJECT_DIR/Wallpapers" "$target_bundle/Contents/Resources/"
    fi
    
    # Badges & emblems
    for asset in HeaderBadge.png HeaderBadge.jpg NanoEmblem.jpg GenieDynamic_Thumbnail.png GoldenGateDynamic_Thumbnail.png; do
        if [ -f "$PROJECT_DIR/Sources/GoldGate/$asset" ]; then
            cp "$PROJECT_DIR/Sources/GoldGate/$asset" "$target_bundle/Contents/Resources/"
        fi
    done
}

# 5. Assemble Direct Release Bundle
echo "==> [4/7] Assembling Direct Release App Bundle..."
mkdir -p "$DIRECT_BUILD_DIR"
assemble_bundle "$DIRECT_BUILD_DIR/$APP_NAME.app" "$DEVID_BIN"

# Detect signing identities.
#
# The two channels need DIFFERENT certificates, and using the wrong one is a
# silent failure until Gatekeeper or App Review rejects the result:
#
#   Direct distribution → "Developer ID Application" (then notarized)
#   Mac App Store       → "Apple Distribution" / "3rd Party Mac Developer Application"
find_identity() {
    security find-identity -v -p codesigning | grep "$1" | head -n 1 | awk '{print $2}' || true
}

DEVID_SIGN_ID="$(find_identity "Developer ID Application")"
MAS_SIGN_ID="$(find_identity "Apple Distribution")"
if [ -z "$MAS_SIGN_ID" ]; then
    MAS_SIGN_ID="$(find_identity "3rd Party Mac Developer Application")"
fi

INSTALLER_ID=$(security find-identity -v | grep "Mac Installer Distribution" | head -n 1 | awk '{print $2}' || true)
if [ -z "$INSTALLER_ID" ]; then
    INSTALLER_ID=$(security find-identity -v | grep "3rd Party Mac Developer Installer" | head -n 1 | awk '{print $2}' || true)
fi

# Sign Direct Release with Developer ID + Hardened Runtime.
if [ -n "$DEVID_SIGN_ID" ]; then
    echo "Signing Direct Release with Developer ID: $DEVID_SIGN_ID..."
    codesign --force --options runtime --timestamp \
        --sign "$DEVID_SIGN_ID" "$DIRECT_BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --options runtime --timestamp \
        --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.entitlements" \
        --sign "$DEVID_SIGN_ID" "$DIRECT_BUILD_DIR/$APP_NAME.app"
else
    echo "WARNING: no 'Developer ID Application' certificate found."
    echo "         Signing the direct build ad-hoc — it CANNOT be notarized,"
    echo "         and Gatekeeper will refuse it on any other Mac."
    codesign --force --options runtime --sign - "$DIRECT_BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --options runtime \
        --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.entitlements" \
        --sign - "$DIRECT_BUILD_DIR/$APP_NAME.app"
fi

# 6. Assemble App Store Release Bundle & Package
echo "==> [5/7] Assembling App Store Bundle & PKG..."
mkdir -p "$APPSTORE_BUILD_DIR"
assemble_bundle "$APPSTORE_BUILD_DIR/$APP_NAME.app" "$MAS_BIN"

if [ -n "$MAS_SIGN_ID" ]; then
    echo "Signing App Store bundle with: $MAS_SIGN_ID..."
    codesign --force --options runtime --sign "$MAS_SIGN_ID" "$APPSTORE_BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign "$MAS_SIGN_ID" "$APPSTORE_BUILD_DIR/$APP_NAME.app"
else
    echo "WARNING: no Apple Distribution certificate — signing App Store bundle ad-hoc."
    echo "         This .pkg cannot be uploaded to App Store Connect."
    codesign --force --options runtime --sign - "$APPSTORE_BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    codesign --force --options runtime --entitlements "$PROJECT_DIR/Sources/GoldGate/Genie.AppStore.entitlements" --sign - "$APPSTORE_BUILD_DIR/$APP_NAME.app"
fi

# Verify the App Store bundle really is sandboxed before it goes any further.
if codesign -d --entitlements :- "$APPSTORE_BUILD_DIR/$APP_NAME.app" 2>/dev/null | \
   grep -A1 "com.apple.security.app-sandbox" | grep -q "<true/>"; then
    echo "App Store bundle: app-sandbox enabled ✓"
else
    echo "ERROR: App Store bundle is not sandboxed — App Review will reject it." >&2
    exit 1
fi

# And that the direct build is NOT sandboxed (it would lose its whole feature set).
if codesign -d --entitlements :- "$DIRECT_BUILD_DIR/$APP_NAME.app" 2>/dev/null | \
   grep -A1 "com.apple.security.app-sandbox" | grep -q "<true/>"; then
    echo "ERROR: the direct build came out sandboxed — wrong entitlements file." >&2
    exit 1
fi

rm -f "$PKG_OUTPUT"
if [ -n "$INSTALLER_ID" ]; then
    echo "Building signed App Store Installer PKG ($PKG_OUTPUT)..."
    productbuild --component "$APPSTORE_BUILD_DIR/$APP_NAME.app" /Applications --sign "$INSTALLER_ID" "$PKG_OUTPUT" || {
        echo "Warning: productbuild with installer identity encountered issue, building standard package..."
        productbuild --component "$APPSTORE_BUILD_DIR/$APP_NAME.app" /Applications "$PKG_OUTPUT"
    }
else
    echo "Building App Store Installer PKG ($PKG_OUTPUT)..."
    productbuild --component "$APPSTORE_BUILD_DIR/$APP_NAME.app" /Applications "$PKG_OUTPUT"
fi

# 7. Package DMG and ZIP for Direct Distribution
echo "==> [6/7] Creating Distributable DMG and ZIP..."
DMG_STAGE="$DIRECT_BUILD_DIR/dmg_stage"
rm -rf "$DMG_STAGE" "$DMG_OUTPUT" "$ZIP_OUTPUT"
mkdir -p "$DMG_STAGE"

cp -R "$DIRECT_BUILD_DIR/$APP_NAME.app" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create -volname "Genie Installer" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DMG_OUTPUT"
if [ -n "$DEVID_SIGN_ID" ]; then
    codesign --force --timestamp --sign "$DEVID_SIGN_ID" "$DMG_OUTPUT" 2>/dev/null || true
fi

cd "$DIRECT_BUILD_DIR"
zip -qry "$ZIP_OUTPUT" "$APP_NAME.app"
cd "$PROJECT_DIR"

# 7b. Notarize the direct-distribution build.
#
# Without this, macOS refuses to launch Genie on any Mac but this one:
# Gatekeeper shows "Apple could not verify Genie is free of malware". Signing
# with Developer ID is only half of it — the notary service has to see the build
# too, and the ticket has to be stapled so it works offline.
#
# Credentials, in order of preference:
#   GENIE_NOTARY_PROFILE   a notarytool keychain profile, created once with
#                          xcrun notarytool store-credentials GENIE_NOTARY \
#                            --apple-id <id> --team-id <team> --password <app-specific>
#   APPLE_ID + APP_SPECIFIC_PASSWORD + GENIE_TEAM_ID
#
# Set GENIE_SKIP_NOTARIZE=1 for a local build you are not distributing.
NOTARY_PROFILE="${GENIE_NOTARY_PROFILE:-GENIE_NOTARY}"
APPLE_ID="${APPLE_ID:-nicholas.dudek@icloud.com}"
NOTARY_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"
TEAM_ID="${GENIE_TEAM_ID:-}"

notarize_and_staple() {
    local artifact="$1"
    echo "    Submitting $(basename "$artifact") to the Apple notary service..."
    if xcrun notarytool submit "$artifact" --keychain-profile "$NOTARY_PROFILE" --wait; then
        :
    elif [ -n "$NOTARY_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
        xcrun notarytool submit "$artifact" \
            --apple-id "$APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$TEAM_ID" --wait
    else
        echo "    ERROR: notarization failed and no fallback credentials are set." >&2
        return 1
    fi
    echo "    Stapling ticket to $(basename "$artifact")..."
    xcrun stapler staple "$artifact"
}

if [ "${GENIE_SKIP_NOTARIZE:-0}" = "1" ]; then
    echo "==> Skipping notarization (GENIE_SKIP_NOTARIZE=1)."
    echo "    The DMG will not open on other Macs."
elif [ -z "$DEVID_SIGN_ID" ]; then
    echo "==> Skipping notarization: the build is not Developer ID signed."
    echo "    The DMG will not open on other Macs."
else
    echo "==> Notarizing direct-distribution build..."
    # Staple the .app first, then repackage, so the DMG carries a stapled app.
    if notarize_and_staple "$DIRECT_BUILD_DIR/$APP_NAME.app"; then
        rm -rf "$DMG_STAGE" "$DMG_OUTPUT" "$ZIP_OUTPUT"
        mkdir -p "$DMG_STAGE"
        cp -R "$DIRECT_BUILD_DIR/$APP_NAME.app" "$DMG_STAGE/"
        ln -s /Applications "$DMG_STAGE/Applications"
        hdiutil create -volname "Genie Installer" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DMG_OUTPUT"
        codesign --force --timestamp --sign "$DEVID_SIGN_ID" "$DMG_OUTPUT"
        notarize_and_staple "$DMG_OUTPUT" || echo "WARNING: DMG notarization failed."

        cd "$DIRECT_BUILD_DIR"
        zip -qry "$ZIP_OUTPUT" "$APP_NAME.app"
        cd "$PROJECT_DIR"

        echo "==> Verifying Gatekeeper acceptance..."
        spctl --assess --type execute --verbose=2 "$DIRECT_BUILD_DIR/$APP_NAME.app" || \
            echo "WARNING: spctl did not accept the bundle."
    else
        echo "WARNING: app notarization failed — DMG left un-notarized."
    fi
fi

# 8. Install finalized app to /Applications & shortcuts
echo "==> [7/7] Updating /Applications/$APP_NAME.app & Desktop shortcuts..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$DIRECT_BUILD_DIR/$APP_NAME.app" "/Applications/$APP_NAME.app"
ln -sfn "/Applications/$APP_NAME.app" "$HOME/Desktop/$APP_NAME.app" 2>/dev/null || true
ln -sfn "/Applications/$APP_NAME.app" "$HOME/$APP_NAME.app" 2>/dev/null || true

echo "=========================================================="
echo "  ✅ GOLD GATE / GENIE FINALIZATION COMPLETE!"
echo "  Application Bundle: $DIRECT_BUILD_DIR/$APP_NAME.app"
echo "  DMG Disk Image:     $DMG_OUTPUT ($(du -h "$DMG_OUTPUT" | awk '{print $1}'))"
echo "  Zip Archive:        $ZIP_OUTPUT ($(du -h "$ZIP_OUTPUT" | awk '{print $1}'))"
if [ -f "$PKG_OUTPUT" ]; then
    echo "  Mac App Store PKG:  $PKG_OUTPUT ($(du -h "$PKG_OUTPUT" | awk '{print $1}'))"
fi
echo "  Installed to:       /Applications/$APP_NAME.app"
echo "  Desktop Shortcut:   $HOME/Desktop/$APP_NAME.app"
echo "=========================================================="
