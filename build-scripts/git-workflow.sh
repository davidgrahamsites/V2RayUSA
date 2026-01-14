#!/bin/bash
#
# git-workflow.sh
# Ensures all changes are committed and pushed before build
#

set -euo pipefail

cd "$(dirname "$0")/.."

echo "🔍 Checking Git status..."

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "⚠️  Not a Git repository. Initializing..."
    git init
    git add .
    git commit -m "Initial commit: V2RayUSA project"
    echo "✅ Git repository initialized"
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  You have uncommitted changes!"
    echo ""
    echo "Modified files:"
    git status --short
    echo ""
    read -p "Commit all changes now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        BUILD_NUM=$(date +%Y%m%d-%H%M%S)
        git commit -m "Build ${BUILD_NUM}: Pre-build auto-commit"
        echo "✅ Changes committed"
    else
        echo "❌ Build cancelled - please commit your changes first"
        exit 1
    fi
fi

# Get current version from Info.plist
VERSION=$(defaults read "$(pwd)/V2RayUSA/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_TAG="v${VERSION}-${COMMIT_HASH}"

echo "📝 Build tag: ${BUILD_TAG}"

# Create Git tag if it doesn't exist
if git rev-parse "${BUILD_TAG}" >/dev/null 2>&1; then
    echo "ℹ️  Tag ${BUILD_TAG} already exists"
else
    git tag -a "${BUILD_TAG}" -m "Build ${BUILD_TAG}"
    echo "✅ Created tag: ${BUILD_TAG}"
fi

# Push to remote if configured
if git remote | grep -q origin; then
    echo "📤 Pushing to remote..."
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || echo "⚠️  Could not push to remote (branch may not exist)"
    git push --tags 2>/dev/null || echo "⚠️  Could not push tags"
    echo "✅ Pushed to GitHub"
else
    echo "ℹ️  No remote 'origin' configured - skipping push"
    echo "   To add remote: git remote add origin https://github.com/yourusername/v2rayusa.git"
fi

echo "✅ Git workflow complete - ready to build"
