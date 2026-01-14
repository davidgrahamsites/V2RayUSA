# V2RayUSA - Build Guide

Complete build instructions for creating a reproducible, arm64-native macOS .app bundle and distributable DMG.

## Prerequisites

### Required Software

1. **macOS**: 12.0 (Monterey) or later
2. **Xcode**: 14.0 or later (for command-line tools)
   ```bash
   xcode-select --install
   ```
3. **Git**: For version control
   ```bash
   git --version
   ```

### Verify Your Mac Architecture

```bash
uname -m
# Expected output: arm64
```

If output is `x86_64`, you're on an Intel Mac. This build only targets Apple Silicon.

## Quick Build

```bash
# Clone the repository
git clone https://github.com/yourusername/v2rayusa.git
cd V2RayUSA

# Run the complete build pipeline
chmod +x build-scripts/build.sh
./build-scripts/build.sh
```

The script will:
1. Commit all changes to Git and push to GitHub
2. Download V2Ray core (arm64)
3. Generate Xcode project
4. Build the application
5. Create DMG file
6. Verify architecture and dependencies

**Output**:
- `.app`: `build/Build/Products/Release/V2RayUSA.app`
- `.dmg`: `dist/V2RayUSA.dmg`

## Step-by-Step Build Process

### 1. Clone and Setup

```bash
git clone https://github.com/yourusername/v2rayusa.git
cd V2RayUSA
```

### 2. Git Workflow (Required Before Build)

The build system enforces Git version control:

```bash
# Ensure all changes are committed
git status

# If you have uncommitted changes:
git add .
git commit -m "Your commit message"

# Run Git workflow script
chmod +x build-scripts/git-workflow.sh
./build-scripts/git-workflow.sh
```

** This step**:
- Verifies all changes are committed
- Creates a version tag based on `Info.plist` version + commit hash
- Pushes to GitHub remote (if configured)

**If you don't have a GitHub remote**:
```bash
git remote add origin https://github.com/yourusername/v2rayusa.git
git push -u origin main
```

### 3. Download V2Ray Core

```bash
chmod +x build-scripts/download-v2ray.sh
./build-scripts/download-v2ray.sh
```

This downloads **V2Ray v5.20.0** for macOS arm64 and places it in `V2RayUSA/Resources/v2ray`.

**Pinned version ensures reproducibility**. To change version, edit `download-v2ray.sh`:
```bash
V2RAY_VERSION="5.20.0"  # Change this line
```

### 4. Generate Xcode Project

```bash
chmod +x build-scripts/create-xcode-project.sh
./build-scripts/create-xcode-project.sh
```

Creates:
- `V2RayUSA.xcodeproj/` directory
- `project.pbxproj` with all source files configured
- Xcode workspace structure

### 5. Build with Xcode

```bash
xcodebuild \
  -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  -derivedDataPath ./build \
  clean build
```

**Build configuration**:
- **Architecture**: arm64 only
- **Configuration**: Release (optimized)
- **SDK**: macOS 12.0+
- **Code signing**: Disabled (unsigned builds)

**Output**: `build/Build/Products/Release/V2RayUSA.app`

### 6. Create DMG Distributor

```bash
chmod +x build-scripts/create-dmg.sh
./build-scripts/create-dmg.sh
```

Creates `dist/V2RayUSA.dmg` with:
- V2RayUSA.app
- Applications folder symlink
- README.txt

### 7. Verify Build

```bash
chmod +x build-scripts/verify-build.sh
./build-scripts/verify-build.sh
```

**Verification checks**:
1. ✅ Main binary architecture (arm64)
2. ✅ V2Ray core binary architecture (arm64)
3. ✅ Dynamic library dependencies (system-only)
4. ✅ Bundle structure (Info.plist, Resources, MacOS)
5. ✅ Code signature status
6. ✅ DMG integrity

## Build Outputs

### Directory Structure After Build

```
V2RayUSA/
├── build/
│   └── Build/Products/Release/
│       └── V2RayUSA.app        ← Double-clickable app
├── dist/
│   └── V2RayUSA.dmg            ← Distributable DMG
├── V2RayUSA/                   ← Source files
│   ├── *.swift files
│   ├── Info.plist
│   ├── Resources/
│   │   ├── v2ray               ← V2Ray core binary (arm64)
│   │   └── Assets.xcassets/
│   └── ...
└── build-scripts/              ← Build automation
```

### App Bundle Structure

```
V2RayUSA.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── V2RayUSA            ← Main executable (arm64)
│   ├── Resources/
│   │   ├── v2ray               ← V2Ray core (arm64)
│   │   └── Assets.car          ← Compiled assets
│   └── _CodeSignature/         ← (if signed)
```

## Verification Commands

### Check Architecture

```bash
# Main app binary
file build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA
# Expected: Mach-O 64-bit executable arm64

# V2Ray binary
file build/Build/Products/Release/V2RayUSA.app/Contents/Resources/v2ray
# Expected: Mach-O 64-bit executable arm64

# Lipo info (single architecture)
lipo -info build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA
# Expected: Non-fat file: arm64
```

### Check Dependencies

```bash
# List dynamic libraries
otool -L build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA

# Expected output (system frameworks only):
#   @rpath/libswiftCore.dylib
#   /System/Library/Frameworks/AppKit.framework/...
#   /System/Library/Frameworks/Foundation.framework/...
#   /usr/lib/libSystem.B.dylib
```

**✅ Good**: All paths start with `/System/Library`, `/usr/lib`, or `@rpath`

**❌ Bad**: Paths like `/usr/local/lib` or `/opt/homebrew` (missing dependencies on clean Macs)

### Check Code Signing

```bash
# Detailed signature info
codesign -dv --verbose=4 build/Build/Products/Release/V2RayUSA.app

# Verify signature (if signed)
codesign -v build/Build/Products/Release/V2RayUSA.app

# For unsigned builds:
# Output: "code object is not signed at all"
```

## Build Reproducibility

### Deterministic Builds

To ensure identical builds:

1. **Same V2Ray version**: Pinned in `download-v2ray.sh`
2. **Same Xcode version**: Check with `xcodebuild -version`
3. **Clean build directory**: `rm -rf build/`
4. **Same Git commit**: Tag frozen in build

### Reproduce a Build

```bash
# Clone at specific tag
git clone https://github.com/yourusername/v2rayusa.git
cd V2RayUSA
git checkout v1.0.0-abc1234  # Your build tag

# Clean build
rm -rf build/ dist/
./build-scripts/build.sh

# Compare with original
diff -r \
  original-build/V2RayUSA.app \
  build/Build/Products/Release/V2RayUSA.app
```

## Code Signing (Optional)

For distribution outside the Mac App Store, you need:

1. **Apple Developer Program** ($99/year)
2. **Developer ID Application Certificate**

### Sign the App

```bash
# Sign app bundle
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --options runtime \
  build/Build/Products/Release/V2RayUSA.app

# Verify
codesign -v build/Build/Products/Release/V2RayUSA.app
```

### Notarize for Distribution

```bash
# Create ZIP for notarization
ditto -c -k --keepParent \
  build/Build/Products/Release/V2RayUSA.app \
  V2RayUSA.zip

# Submit to Apple
xcrun notarytool submit V2RayUSA.zip \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"

# Staple ticket to app
xcrun stapler staple build/Build/Products/Release/V2RayUSA.app
```

**Notarized apps** won't show Gatekeeper warnings on first launch.

## Testing on a Clean Mac

### Simulation Without Clean Mac

```bash
# Remove quarantine attribute (simulates download)
xattr -d com.apple.quarantine build/Build/Products/Release/V2RayUSA.app

# Open app
open build/Build/Products/Release/V2RayUSA.app
```

### Actual Clean Mac Test

1. Mount `dist/V2RayUSA.dmg` on a Mac **without Xcode**
2. Drag to Applications
3. Right-click → Open (bypass Gatekeeper)
4. App should launch without errors

**If "missing library" errors occur**:
- Check `otool -L` output
- Ensure no Homebrew or custom paths in dependencies

## Environment Variables

None required. Build is self-contained.

## Build Time

- **Clean build**: ~2-5 minutes
- **Incremental build**: ~30 seconds
- **DMG creation**: ~10 seconds

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common build issues.

## Next Steps

After building:

1. **Test locally**: `open build/Build/Products/Release/V2RayUSA.app`
2. **Test DMG**: Mount `dist/V2RayUSA.dmg` and test installation
3. **Configure server**: Add your V2Ray server details
4. **Test connection**: Click Connect in menubar

---

**Questions?** See [README.md](README.md) or open an issue on GitHub.
