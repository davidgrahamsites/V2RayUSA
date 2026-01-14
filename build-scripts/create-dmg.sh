#!/bin/bash
#
# create-dmg.sh
# Creates distributable DMG file
#

set -euo pipefail

APP_NAME="V2RayUSA"
BUILD_DIR="build/Build/Products/Release"
DIST_DIR="dist"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

echo "📦 Creating DMG for ${APP_NAME}..."

# Create dist directory
mkdir -p "${DIST_DIR}"

# Check if app exists
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo "❌ ERROR: ${BUILD_DIR}/${APP_NAME}.app not found"
    echo "   Run build first: xcodebuild ..."
    exit 1
fi

# Remove old DMG if exists
rm -f "${DIST_DIR}/${DMG_NAME}"

# Create temporary DMG directory
TMP_DMG_DIR="/tmp/${APP_NAME}_dmg"
rm -rf "${TMP_DMG_DIR}"
mkdir -p "${TMP_DMG_DIR}"

# Copy app to temp directory
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${TMP_DMG_DIR}/"

# Create Applications symlink
ln -s /Applications "${TMP_DMG_DIR}/Applications"

# Create README
cat > "${TMP_DMG_DIR}/README.txt" << 'README_EOF'
V2RayUSA - V2Ray VPN Client for macOS
======================================

Installation:
1. Drag V2RayUSA.app to the Applications folder
2. Open V2RayUSA.app (right-click → Open on first launch)
3. Click the menubar icon and select Preferences
4. Enter your V2Ray server configuration
5. Click Connect to start the VPN

Features:
- Menubar app (no dock icon)
- Supports VMess, VLESS, Trojan protocols
- VPN tunnel chaining support
- Local SOCKS5 proxy on 127.0.0.1:1080

For help and documentation:
https://github.com/yourusername/v2rayusa

Minimum Requirements:
- macOS 12.0 (Monterey) or later
- Apple Silicon (M1/M2/M3) Mac

README_EOF

# Create DMG using hdiutil
echo "Creating DMG..."
hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${TMP_DMG_DIR}" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "${DIST_DIR}/${DMG_NAME}"

# Cleanup
rm -rf "${TMP_DMG_DIR}"

echo "✅ DMG created: ${DIST_DIR}/${DMG_NAME}"

# Get DMG size
DMG_SIZE=$(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1)
echo "   Size: ${DMG_SIZE}"
