#!/bin/bash
# Create DMG installer for S3 Desktop Explorer (macOS)
# Requires: create-dmg (brew install create-dmg)

set -e

APP_NAME="S3 Explorer"
VERSION="0.1.0"
DMG_NAME="S3-Explorer-${VERSION}-macOS"
BUILD_DIR="build/macos/Build/Products/Release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
OUTPUT_DIR="build/macos/dmg"

echo "========================================="
echo "Creating DMG installer"
echo "Version: $VERSION"
echo "========================================="

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found"
    echo "Install with: brew install create-dmg"
    exit 1
fi

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    echo "Run ./scripts/build_macos.sh first"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove old DMG if exists
rm -f "$OUTPUT_DIR/$DMG_NAME.dmg"

echo "Creating DMG..."
create-dmg \
  --volname "$APP_NAME" \
  --volicon "$APP_BUNDLE/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 200 190 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 600 185 \
  "$OUTPUT_DIR/$DMG_NAME.dmg" \
  "$APP_BUNDLE"

echo ""
echo "========================================="
echo "DMG created successfully!"
echo "========================================="
echo "Output: $OUTPUT_DIR/$DMG_NAME.dmg"
echo "Size: $(du -h "$OUTPUT_DIR/$DMG_NAME.dmg" | cut -f1)"
echo ""
