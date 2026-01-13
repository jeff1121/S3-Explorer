#!/bin/bash
# Build script for S3 Desktop Explorer (macOS)
# Usage: ./scripts/build_macos.sh [debug|release]

set -e

BUILD_MODE="${1:-release}"
APP_NAME="S3 Explorer"
VERSION="0.1.0"
BUILD_NUMBER="1"

echo "========================================="
echo "Building S3 Desktop Explorer for macOS"
echo "Build mode: $BUILD_MODE"
echo "Version: $VERSION"
echo "========================================="

# Ensure we're in the app directory
cd "$(dirname "$0")/.."

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
flutter pub get

# Build the macOS app
echo "Building macOS app in $BUILD_MODE mode..."
if [ "$BUILD_MODE" = "debug" ]; then
    flutter build macos --debug
else
    flutter build macos --release
fi

BUILD_DIR="build/macos/Build/Products"
if [ "$BUILD_MODE" = "debug" ]; then
    PRODUCT_DIR="$BUILD_DIR/Debug"
else
    PRODUCT_DIR="$BUILD_DIR/Release"
fi

APP_BUNDLE="$PRODUCT_DIR/$APP_NAME.app"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo "App bundle: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To create a DMG (requires create-dmg):"
echo "  ./scripts/create_dmg.sh"
echo ""
