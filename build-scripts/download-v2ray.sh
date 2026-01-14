#!/bin/bash
#
# download-v2ray.sh
# Downloads V2Ray core binary for macOS arm64
#

set -euo pipefail

V2RAY_VERSION="5.20.0"
DOWNLOAD_URL="https://github.com/v2fly/v2ray-core/releases/download/v${V2RAY_VERSION}/v2ray-macos-arm64-v8a.zip"
RESOURCES_DIR="V2RayUSA/Resources"
OUTPUT_ZIP="/tmp/v2ray-core.zip"

echo "🔄 Downloading V2Ray core v${V2RAY_VERSION} for macOS arm64..."

# Create resources directory if it doesn't exist
mkdir -p "${RESOURCES_DIR}"

# Check if v2ray binary already exists
if [ -f "${RESOURCES_DIR}/v2ray" ]; then
    echo "✅ V2Ray binary already exists at ${RESOURCES_DIR}/v2ray"
    
    # Verify it's arm64
    if file "${RESOURCES_DIR}/v2ray" | grep -q "arm64"; then
        echo "✅ Existing binary is arm64 - skipping download"
        exit 0
    else
        echo "⚠️  Existing binary is not arm64 - re-downloading"
        rm "${RESOURCES_DIR}/v2ray"
    fi
fi

# Download V2Ray
echo "📥 Downloading from ${DOWNLOAD_URL}..."
curl -L -o "${OUTPUT_ZIP}" "${DOWNLOAD_URL}"

# Extract
echo "📦 Extracting..."
unzip -q -o "${OUTPUT_ZIP}" -d /tmp/v2ray-extracted

# Copy binary
cp /tmp/v2ray-extracted/v2ray "${RESOURCES_DIR}/v2ray"
chmod +x "${RESOURCES_DIR}/v2ray"

# Verify architecture
echo "🔍 Verifying architecture..."
file "${RESOURCES_DIR}/v2ray"

if file "${RESOURCES_DIR}/v2ray" | grep -q "arm64"; then
    echo "✅ V2Ray core arm64 binary installed successfully"
else
    echo "❌ ERROR: Downloaded binary is not arm64!"
    exit 1
fi

# Cleanup
rm -f "${OUTPUT_ZIP}"
rm -rf /tmp/v2ray-extracted

echo "✅ V2Ray core v${V2RAY_VERSION} ready for bundling"
