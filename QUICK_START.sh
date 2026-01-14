#!/bin/bash
#
# QUICK_START.sh
# Quick build script without sudo requirements
#

set -euo pipefail

echo "🚀 V2RayUSA Quick Build"
echo "======================="
echo ""

# Check for Xcode
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ Xcode.app not found in /Applications/"
    echo ""
    echo "Please install Xcode from the Mac App Store first."
    exit 1
fi

echo "✅ Xcode found"
echo ""

# Temporarily use Xcode for this session (no sudo needed)
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

echo "📍 Using Xcode at: $DEVELOPER_DIR"
echo ""

# Verify xcodebuild works
if ! "$DEVELOPER_DIR/usr/bin/xcodebuild" -version > /dev/null 2>&1; then
    echo "❌ xcodebuild not working"
    echo ""
    echo "You may need to run manually:"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo "✅ xcodebuild ready"
echo ""

# Download V2Ray if needed
if [ ! -f "V2RayUSA/Resources/v2ray" ]; then
    echo "Step 1/4: Downloading V2Ray core..."
    ./build-scripts/download-v2ray.sh
else
    echo "Step 1/4: V2Ray core already present ✓"
fi
echo ""

# Create Xcode project if needed
if [ ! -f "V2RayUSA.xcodeproj/project.pbxproj" ]; then
    echo "Step 2/4: Creating Xcode project..."
    ./build-scripts/create-xcode-project.sh
else
    echo "Step 2/4: Xcode project already exists ✓"
fi
echo ""

# Build
echo "Step 3/4: Building application..."
"$DEVELOPER_DIR/usr/bin/xcodebuild" \
  -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  -derivedDataPath ./build \
  clean build

echo ""
echo "✅ Build complete!"
echo ""

# Create DMG
echo "Step 4/4: Creating DMG..."
./build-scripts/create-dmg.sh
echo ""

# Verify
echo "🔍 Running verification..."
./build-scripts/verify-build.sh
echo ""

echo "================================================"
echo "✅ SUCCESS! V2RayUSA is ready"
echo "================================================"
echo ""
echo "📦 Outputs:"
echo "   .app: build/Build/Products/Release/V2RayUSA.app"
echo "   .dmg: dist/V2RayUSA.dmg"
echo ""
echo "🚀 Next steps:"
echo "   1. Open: open build/Build/Products/Release/V2RayUSA.app"
echo "   2. Or install DMG: open dist/V2RayUSA.dmg"
echo ""
