#!/bin/bash
#
# build.sh
# Main build orchestrator for V2RayUSA
#

set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

echo "🚀 V2RayUSA Build Pipeline"
echo "=========================="
echo ""

# Step 1: Git workflow
echo "Step 1/5: Git Workflow"
chmod +x build-scripts/git-workflow.sh
./build-scripts/git-workflow.sh
echo ""

# Step 2: Download V2Ray core
echo "Step 2/5: Download V2Ray Core"
chmod +x build-scripts/download-v2ray.sh
./build-scripts/download-v2ray.sh
echo ""

# Step 3: Create Xcode project
echo "Step 3/5: Generate Xcode Project"
chmod +x build-scripts/create-xcode-project.sh
./build-scripts/create-xcode-project.sh
echo ""

# Step 4: Build with xcodebuild
echo "Step 4/5: Build Application"
xcodebuild \
  -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  -derivedDataPath ./build \
  clean build

echo "✅ Build completed successfully"
echo ""

# Step 5: Create DMG
echo "Step 5/5: Create DMG"
chmod +x build-scripts/create-dmg.sh
./build-scripts/create-dmg.sh
echo ""

# Verify build
echo "Running verification..."
chmod +x build-scripts/verify-build.sh
./build-scripts/verify-build.sh
echo ""

echo "✅ BUILD COMPLETE!"
echo ""
echo "Outputs:"
echo "  .app: build/Build/Products/Release/V2RayUSA.app"
echo "  .dmg: dist/V2RayUSA.dmg"
echo ""
echo "Next steps:"
echo "  • Test the .app by double-clicking it"
echo "  • Configure your server in Preferences"
echo "  • Click Connect in the menubar"
echo ""
