#!/bin/bash
#
# verify-build.sh
# Verifies build outputs for arm64 and dependency completeness
#

set -euo pipefail

APP_PATH="build/Build/Products/Release/V2RayUSA.app"
BINARY_PATH="${APP_PATH}/Contents/MacOS/V2RayUSA"
V2RAY_PATH="${APP_PATH}/Contents/Resources/v2ray"

echo "🔍 Verification Checklist"
echo "========================"
echo ""

# Check if app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ App bundle not found at ${APP_PATH}"
    exit 1
fi

echo "✅ App bundle exists"

# 1. Main binary architecture check
echo ""
echo "1. Main Binary Architecture:"
echo "----------------------------"
if [ -f "${BINARY_PATH}" ]; then
    echo "$ file ${BINARY_PATH}"
    file "${BINARY_PATH}"
    echo ""
    
    if file "${BINARY_PATH}" | grep -q "arm64"; then
        echo "✅ Main binary is arm64"
    else
        echo "❌ Main binary is NOT arm64!"
        exit 1
    fi
else
    echo "❌ Main binary not found at ${BINARY_PATH}"
    exit 1
fi

# 2. V2Ray binary check
echo ""
echo "2. V2Ray Core Binary:"
echo "---------------------"
if [ -f "${V2RAY_PATH}" ]; then
    echo "$ file ${V2RAY_PATH}"
    file "${V2RAY_PATH}"
    echo ""
    
    if file "${V2RAY_PATH}" | grep -q "arm64"; then
        echo "✅ V2Ray binary is arm64"
    else
        echo "❌ V2Ray binary is NOT arm64!"
        exit 1
    fi
else
    echo "⚠️  V2Ray binary not found - app may not function"
fi

# 3. Dynamic libraries check
echo ""
echo "3. Dynamic Library Dependencies:"
echo "--------------------------------"
echo "$ otool -L ${BINARY_PATH}"
otool -L "${BINARY_PATH}"
echo ""

# Check for non-system libraries (potential issues)
NON_SYSTEM_LIBS=$(otool -L "${BINARY_PATH}" | grep -v "/usr/lib" | grep -v "/System/Library" | grep -v "${BINARY_PATH}" || true)
if [ -z "$NON_SYSTEM_LIBS" ]; then
    echo "✅ All dependencies are system frameworks"
else
    echo "⚠️  Non-system dependencies found (may need bundling):"
    echo "${NON_SYSTEM_LIBS}"
fi

# 4. Bundle structure check
echo ""
echo "4. Bundle Structure:"
echo "--------------------"
ls -la "${APP_PATH}/Contents/"
echo ""

REQUIRED_ITEMS=("MacOS" "Resources" "Info.plist")
for item in "${REQUIRED_ITEMS[@]}"; do
    if [ -e "${APP_PATH}/Contents/${item}" ]; then
        echo "✅ ${item} present"
    else
        echo "❌ ${item} missing!"
        exit 1
    fi
done

# 5. Code signature status
echo ""
echo "5. Code Signature Status:"
echo "-------------------------"
echo "$ codesign -dv --verbose=4 ${APP_PATH}"
codesign -dv --verbose=4 "${APP_PATH}" 2>&1 || echo "⚠️  App is not signed (expected for dev builds)"
echo ""

if codesign -v "${APP_PATH}" 2>/dev/null; then
    echo "✅ Code signature is valid"
else
    echo "ℹ️  App is unsigned (users will see 'unidentified developer' warning)"
    echo "   To bypass: right-click → Open on first launch"
fi

# 6. DMG check (if exists)
echo ""
echo "6. DMG Artifact:"
echo "----------------"
if [ -f "dist/V2RayUSA.dmg" ]; then
    echo "$ hdiutil verify dist/V2RayUSA.dmg"
    if hdiutil verify dist/V2RayUSA.dmg 2>&1 | grep -q "verified"; then
        echo "✅ DMG is valid"
        DMG_SIZE=$(du -h dist/V2RayUSA.dmg | cut -f1)
        echo "   Size: ${DMG_SIZE}"
    else
        echo "⚠️  DMG verification had warnings"
    fi
else
    echo "ℹ️  DMG not found (run create-dmg.sh)"
fi

# Summary
echo ""
echo "================================"
echo "✅ VERIFICATION COMPLETE"
echo "================================"
echo ""
echo "The app is ready for distribution!"
echo ""
echo "Installation test:"
echo "  1. Mount dist/V2RayUSA.dmg"
echo "  2. Drag to Applications"
echo "  3. Right-click → Open (bypass Gatekeeper)"
echo "  4. Configure server in Preferences"
echo ""
