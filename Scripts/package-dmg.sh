#!/bin/bash
set -euo pipefail

# LiveWall Pro — DMG Packaging Script
# Creates a signed, notarized DMG for distribution
#
# Prerequisites:
#   - Valid Apple Developer ID Application certificate in Keychain
#   - App-specific password for notarization stored in Keychain
#   - Set environment variables:
#     DEVELOPER_ID_APPLICATION  — "Developer ID Application: Your Name (TEAM_ID)"
#     APPLE_ID                  — your Apple ID email
#     APPLE_TEAM_ID             — your team ID
#     NOTARIZATION_KEYCHAIN_PROFILE — keychain profile for notarytool

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/LiveWallPro.app"
DMG_TEMP="$BUILD_DIR/dmg_staging"
DMG_PATH="$BUILD_DIR/LiveWallPro.dmg"
DMG_VOLUME_NAME="LiveWall Pro"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Run ./Scripts/build.sh first"
    exit 1
fi

echo "=== DMG Packaging ==="

# Step 1: Sign the app (if DEVELOPER_ID_APPLICATION is set)
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
    echo "Signing app with: $DEVELOPER_ID_APPLICATION"
    codesign --deep --force --options runtime \
        --sign "$DEVELOPER_ID_APPLICATION" \
        --entitlements "$PROJECT_DIR/LiveWallPro/Support/LiveWallPro.entitlements" \
        "$APP_PATH"

    echo "Verifying signature..."
    codesign --verify --deep --strict "$APP_PATH"
    spctl --assess --type execute "$APP_PATH" || echo "Warning: spctl assessment may fail without notarization"
    echo "Signing complete."
else
    echo "Warning: DEVELOPER_ID_APPLICATION not set — skipping code signing"
    echo "Set it to your signing identity for distribution builds"
fi

echo ""

# Step 2: Create DMG
echo "Creating DMG..."
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create symlink to Applications
ln -s /Applications "$DMG_TEMP/Applications"

# Remove any existing DMG
rm -f "$DMG_PATH"

# Create DMG
hdiutil create \
    -volname "$DMG_VOLUME_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

rm -rf "$DMG_TEMP"

echo "DMG created: $DMG_PATH"
echo ""

# Step 3: Sign DMG (if signing identity available)
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
    echo "Signing DMG..."
    codesign --force --sign "$DEVELOPER_ID_APPLICATION" "$DMG_PATH"
    echo "DMG signed."
    echo ""
fi

# Step 4: Notarize (if credentials available)
if [ -n "${NOTARIZATION_KEYCHAIN_PROFILE:-}" ]; then
    echo "Submitting for notarization..."
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARIZATION_KEYCHAIN_PROFILE" \
        --wait

    echo "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"

    echo "Verifying stapled ticket..."
    xcrun stapler validate "$DMG_PATH"

    echo "Notarization complete."
else
    echo "Skipping notarization — NOTARIZATION_KEYCHAIN_PROFILE not set"
    echo ""
    echo "To set up notarization:"
    echo "  1. xcrun notarytool store-credentials \"LiveWallPro\" \\"
    echo "       --apple-id \"\$APPLE_ID\" \\"
    echo "       --team-id \"\$APPLE_TEAM_ID\" \\"
    echo "       --password \"app-specific-password\""
    echo "  2. export NOTARIZATION_KEYCHAIN_PROFILE=\"LiveWallPro\""
    echo "  3. Re-run this script"
fi

echo ""
echo "=== Packaging Complete ==="
echo "DMG: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
