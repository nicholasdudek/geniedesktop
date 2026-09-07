#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="$PROJECT_DIR/web/assets/icons/app_icon.png"
CATALOG_DIR="$PROJECT_DIR/Sources/GoldGate/Assets.xcassets"
APPICON_SET="$CATALOG_DIR/AppIcon.appiconset"

echo "==> Creating Assets.xcassets structure..."
rm -rf "$CATALOG_DIR"
mkdir -p "$APPICON_SET"

cat << 'JSON' > "$CATALOG_DIR/Contents.json"
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

# Generate icon sizes for macOS
sips -z 16 16     "$ICON_SRC" --out "$APPICON_SET/icon_16x16.png"
sips -z 32 32     "$ICON_SRC" --out "$APPICON_SET/icon_16x16@2x.png"
sips -z 32 32     "$ICON_SRC" --out "$APPICON_SET/icon_32x32.png"
sips -z 64 64     "$ICON_SRC" --out "$APPICON_SET/icon_32x32@2x.png"
sips -z 128 128   "$ICON_SRC" --out "$APPICON_SET/icon_128x128.png"
sips -z 256 256   "$ICON_SRC" --out "$APPICON_SET/icon_128x128@2x.png"
sips -z 256 256   "$ICON_SRC" --out "$APPICON_SET/icon_256x256.png"
sips -z 512 512   "$ICON_SRC" --out "$APPICON_SET/icon_256x256@2x.png"
sips -z 512 512   "$ICON_SRC" --out "$APPICON_SET/icon_512x512.png"
sips -z 1024 1024 "$ICON_SRC" --out "$APPICON_SET/icon_512x512@2x.png"

cat << 'JSON' > "$APPICON_SET/Contents.json"
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "icon_32x32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "icon_32x32@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "icon_128x128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "icon_128x128@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "icon_256x256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "icon_256x256@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "icon_512x512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "icon_512x512@2x.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "==> Compiling Asset Catalog with actool..."
mkdir -p "$PROJECT_DIR/build/compiled_assets"
actool "$CATALOG_DIR" \
  --compile "$PROJECT_DIR/build/compiled_assets" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$PROJECT_DIR/build/compiled_assets/assetcatalog_generated_info.plist"

ls -la "$PROJECT_DIR/build/compiled_assets"
echo "==> Done!"
