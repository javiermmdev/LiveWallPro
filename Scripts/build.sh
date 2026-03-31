#!/bin/bash
set -euo pipefail

# LiveWall Pro — Build Script
# Usage: ./Scripts/build.sh [debug|release]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_CONFIG="${1:-release}"
SCHEME="LiveWallPro"
PROJECT="$PROJECT_DIR/LiveWallPro.xcodeproj"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/LiveWallPro.xcarchive"
APP_PATH="$BUILD_DIR/LiveWallPro.app"

echo "=== LiveWall Pro Build ==="
echo "Configuration: $BUILD_CONFIG"
echo ""

# Clean
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [ "$BUILD_CONFIG" = "debug" ]; then
    echo "Building debug..."
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ONLY_ACTIVE_ARCH=YES \
        2>&1 | tail -20

    DEBUG_APP="$BUILD_DIR/DerivedData/Build/Products/Debug/LiveWallPro.app"

    if [ -f "$DEBUG_APP/Contents/MacOS/LiveWallPro" ]; then
        echo ""
        echo "Debug build complete."
        echo "App: $DEBUG_APP"
        echo "Executable OK."
    else
        echo ""
        echo "ERROR: Build succeeded but no executable found."
        echo "Check Xcode project configuration."
        exit 1
    fi
    exit 0
fi

# Release: build with archive, then extract the app from the archive directly
echo "Archiving release build..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    SKIP_INSTALL=NO \
    2>&1 | tail -20

echo ""

# Extract app directly from archive (avoids exportArchive signing issues)
ARCHIVE_APP="$ARCHIVE_PATH/Products/Applications/LiveWallPro.app"

if [ -f "$ARCHIVE_APP/Contents/MacOS/LiveWallPro" ]; then
    echo "Executable found in archive. Copying..."
    cp -R "$ARCHIVE_APP" "$APP_PATH"
    echo ""
    echo "=== Build Complete ==="
    echo "App: $APP_PATH"
    echo ""
    echo "To create a DMG, run: ./Scripts/package-dmg.sh"
else
    echo "ERROR: No executable found in archive."
    echo ""
    echo "Contents of archive app bundle:"
    ls -laR "$ARCHIVE_APP/Contents/" 2>/dev/null || echo "  Archive app not found"
    echo ""
    echo "Try building from Xcode instead:"
    echo "  1. Open LiveWallPro.xcodeproj"
    echo "  2. Product > Archive"
    echo "  3. Distribute App > Copy App"
    exit 1
fi
