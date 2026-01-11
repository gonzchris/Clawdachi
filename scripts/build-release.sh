#!/bin/bash
set -e

# Local build and DMG creation script for testing
# Usage: ./scripts/build-release.sh [version]

APP_NAME="Clawdachi"
PROJECT="Clawdachi.xcodeproj"
SCHEME="Clawdachi"
VERSION="${1:-1.0.0}"
OUTPUT_DIR="./build"
SCRIPTS_DIR="./scripts"

echo "========================================"
echo "Building $APP_NAME v$VERSION"
echo "========================================"

# Clean and create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Build archive
echo ""
echo "Step 1: Building Release archive..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$OUTPUT_DIR/$APP_NAME.xcarchive" \
  -quiet

echo "Archive created at $OUTPUT_DIR/$APP_NAME.xcarchive"

# Create export options plist
cat > "$OUTPUT_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>98VVU5LJ35</string>
</dict>
</plist>
EOF

# Export app
echo ""
echo "Step 2: Exporting app with Developer ID signing..."
xcodebuild -exportArchive \
  -archivePath "$OUTPUT_DIR/$APP_NAME.xcarchive" \
  -exportPath "$OUTPUT_DIR/export" \
  -exportOptionsPlist "$OUTPUT_DIR/ExportOptions.plist" \
  -quiet

echo "App exported to $OUTPUT_DIR/export/$APP_NAME.app"

# Verify code signature
echo ""
echo "Step 3: Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$OUTPUT_DIR/export/$APP_NAME.app"
echo "Code signature verified!"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
  echo ""
  echo "Warning: create-dmg not installed. Install with: brew install create-dmg"
  echo "Skipping DMG creation."
  echo ""
  echo "Build complete: $OUTPUT_DIR/export/$APP_NAME.app"
  exit 0
fi

# Create DMG
echo ""
echo "Step 4: Creating DMG..."
mkdir -p "$OUTPUT_DIR/dmg-staging"
cp -R "$OUTPUT_DIR/export/$APP_NAME.app" "$OUTPUT_DIR/dmg-staging/"

create-dmg \
  --volname "$APP_NAME" \
  --volicon "$OUTPUT_DIR/export/$APP_NAME.app/Contents/Resources/AppIcon.icns" \
  --background "$SCRIPTS_DIR/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 80 \
  --icon "$APP_NAME.app" 140 180 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 400 180 \
  --no-internet-enable \
  "$OUTPUT_DIR/$APP_NAME-$VERSION.dmg" \
  "$OUTPUT_DIR/dmg-staging/" || true

# Sign the DMG
echo ""
echo "Step 5: Signing DMG..."
codesign --force --sign "Developer ID Application" \
  --options runtime \
  "$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"

echo ""
echo "========================================"
echo "Build complete!"
echo "========================================"
echo ""
echo "Output files:"
echo "  App: $OUTPUT_DIR/export/$APP_NAME.app"
echo "  DMG: $OUTPUT_DIR/$APP_NAME-$VERSION.dmg"
echo ""
echo "To notarize the DMG:"
echo "  xcrun notarytool submit '$OUTPUT_DIR/$APP_NAME-$VERSION.dmg' \\"
echo "    --apple-id 'YOUR_APPLE_ID' \\"
echo "    --team-id '98VVU5LJ35' \\"
echo "    --password 'APP_SPECIFIC_PASSWORD' \\"
echo "    --wait"
echo ""
echo "Then staple:"
echo "  xcrun stapler staple '$OUTPUT_DIR/$APP_NAME-$VERSION.dmg'"
