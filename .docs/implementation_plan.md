# V2RAY macOS App - Implementation Plan

This plan outlines the creation of a production-ready, native Swift macOS application for V2RAY VPN with full arm64 support, reproducible builds, and comprehensive Git integration.

## Goal Description

Build a native macOS menubar application for Apple Silicon that:
- Runs V2RAY core for USA server connections
- Supports VPN tunnel chaining (V2RAY → Astrill or other VPN providers)
- Provides a clean, simple menubar interface for connection management
- Delivers a self-contained, double-clickable `.app` bundle
- Includes automated build pipeline with Git backup/versioning
- Produces distributable `.dmg` artifact for easy installation
- Ensures reproducibility with pinned dependencies and versioned environments

## User Review Required

> [!IMPORTANT]
> **App Configuration Needed**
> Before proceeding to implementation, I need the following information:
> 
> 1. **App Name**: What should the application be called? (e.g., "V2RayUSA", "SecureVPN", etc.)
> 2. **Bundle Identifier**: Preferred reverse-domain format (e.g., `com.yourdomain.v2rayusa`)
> 3. **USA Server Details**: Do you have V2RAY server configuration (VMess/VLESS JSON config), or should I create a template?
> 4. **Astrill Integration**: How will the app detect/route through Astrill? (System network order, SOCKS proxy, specific interface?)
> 5. **Minimum macOS Version**: Target macOS 11.0+ (Big Sur), 12.0+ (Monterey), or 13.0+ (Ventura)?

> [!WARNING]
> **V2RAY Core Binary**
> The app will need the V2RAY core binary (arm64). Options:
> - **Option 1**: Download pre-built arm64 binary from v2ray-core releases during build
> - **Option 2**: You provide a pre-compiled binary
> - **Option 3**: Build from source as part of the pipeline (slower, requires Go toolchain)
> 
> **Please specify your preference.**

> [!CAUTION]
> **Code Signing & Distribution**
> - Without Apple Developer account code signing, the app will show "unidentified developer" warnings on first launch
> - Users will need to right-click → Open to bypass Gatekeeper
> - For production distribution, you'll eventually need:
>   - Apple Developer Program membership ($99/year)
>   - Developer ID certificate for signing
>   - Notarization for distribution outside Mac App Store
> 
> **The build system will work without signing, but I'll include optional signing steps for when you're ready.**

---

## Proposed Changes

### Component 1: Project Structure & Configuration

#### [NEW] [V2RayUSA Directory Structure](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/)
```
V2RayUSA/
├── V2RayUSA.xcodeproj/          # Xcode project (generated)
├── V2RayUSA/                     # Main app source
│   ├── V2RayUSAApp.swift        # App entry point
│   ├── AppDelegate.swift        # macOS lifecycle & menubar
│   ├── Views/
│   │   ├── MenuBarView.swift    # Menubar icon & menu
│   │   └── PreferencesView.swift # Settings window
│   ├── Managers/
│   │   ├── V2RayManager.swift   # V2RAY core process manager
│   │   ├── TunnelManager.swift  # VPN chaining logic
│   │   └── ConfigManager.swift  # Server config management
│   ├── Models/
│   │   └── ServerConfig.swift   # Data models
│   ├── Resources/
│   │   ├── v2ray-core           # V2RAY binary (arm64)
│   │   ├── server-config.json   # Default server config
│   │   └── Assets.xcassets/     # App icon & images
│   ├── Info.plist
│   └── V2RayUSA.entitlements
├── build-scripts/
│   ├── build.sh                 # Main build orchestrator
│   ├── download-v2ray.sh        # Fetch V2RAY core binary
│   ├── create-dmg.sh            # DMG generator
│   ├── verify-build.sh          # Architecture & dependency checks
│   └── git-workflow.sh          # Pre-build commit/push automation
├── environment.yml              # Conda env for build tools
├── BUILD.md                     # Complete build documentation
├── TROUBLESHOOTING.md           # Common issues & fixes
└── README.md                    # Project overview
```

#### [NEW] [Info.plist](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Info.plist)
- Configure bundle identifier, version, minimum macOS version
- Set `LSUIElement` = YES for menubar-only app (no dock icon)
- Define required permissions (network, system extension if needed)

#### [NEW] [V2RayUSA.entitlements](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/V2RayUSA.entitlements)
- Network client entitlement
- User-selected file access (for config import)
- Hardened runtime settings

---

### Component 2: Swift Application Core

#### [NEW] [V2RayUSAApp.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/V2RayUSAApp.swift)
SwiftUI App entry point:
- Initialize `NSApplicationDelegate` for menubar integration
- Set up app lifecycle observers
- Configure logging system

#### [NEW] [AppDelegate.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/AppDelegate.swift)
NSApplicationDelegate implementation:
- Create menubar (status bar) item
- Handle app activation, termination
- Manage V2RayManager lifecycle

#### [NEW] [MenuBarView.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Views/MenuBarView.swift)
SwiftUI view for menubar menu:
- Connection status indicator (🔴 Disconnected / 🟢 Connected)
- Connect/Disconnect toggle
- Server selection submenu
- Preferences option
- Quit option

#### [NEW] [PreferencesView.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Views/PreferencesView.swift)
Settings window:
- Server configuration editor (JSON or form-based)
- Auto-start on login toggle
- Tunnel chaining options
- View logs button

---

### Component 3: V2RAY Core Integration

#### [NEW] [V2RayManager.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Managers/V2RayManager.swift)
Core process management:
```swift
- startV2Ray(config: ServerConfig) -> Bool
  - Launch v2ray-core binary as subprocess
  - Set up local SOCKS5 proxy (default: 127.0.0.1:1080)
  - Monitor process health
  
- stopV2Ray()
  - Gracefully terminate subprocess
  - Clean up resources
  
- getConnectionStatus() -> ConnectionStatus
  - Check if process is running
  - Validate proxy connectivity
  
- updateConfig(_ config: ServerConfig)
  - Write new config.json
  - Restart V2RAY if active
```

#### [NEW] [TunnelManager.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Managers/TunnelManager.swift)
VPN chaining logic:
```swift
- detectUpstreamVPN() -> String?
  - Check for active VPN interfaces (utun*, ppp*)
  - Detect Astrill or other VPN by interface name/route table
  
- configureRouting(v2rayProxy: String, upstreamVPN: String?)
  - Set system proxy to V2RAY SOCKS5
  - Route V2RAY traffic through upstream VPN if detected
  - Use NetworkExtension or system route commands
```

#### [NEW] [ConfigManager.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Managers/ConfigManager.swift)
Configuration persistence:
```swift
- loadServerConfigs() -> [ServerConfig]
  - Read from UserDefaults or JSON file
  
- saveServerConfig(_ config: ServerConfig)
  - Persist to disk with encryption (keychain for credentials)
  
- exportConfig() / importConfig()
  - JSON file import/export for backup/sharing
```

#### [NEW] [ServerConfig.swift](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/V2RayUSA/Models/ServerConfig.swift)
Data model:
```swift
struct ServerConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var serverAddress: String
    var port: Int
    var protocol: V2RayProtocol // VMess, VLESS, Trojan
    var userId: String
    var alterId: Int?
    var encryption: String
    var network: String // tcp, ws, grpc
    // ... additional V2RAY config fields
}
```

---

### Component 4: Build Automation Scripts

#### [NEW] [environment.yml](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/environment.yml)
Conda environment specification:
```yaml
name: v2rayusa-build
channels:
  - conda-forge
dependencies:
  - python=3.11
  - create-dmg  # DMG creation tool
  - jq          # JSON processing for config
  - curl        # Binary downloads
  - git
```

#### [NEW] [build.sh](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/build-scripts/build.sh)
Main build orchestrator:
```bash
#!/bin/bash
set -euo pipefail

# 1. Git workflow: commit and push
./build-scripts/git-workflow.sh

# 2. Download V2RAY core if missing
./build-scripts/download-v2ray.sh

# 3. Build with xcodebuild
xcodebuild \
  -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  -derivedDataPath ./build \
  clean build

# 4. Create .dmg
./build-scripts/create-dmg.sh

# 5. Verify build
./build-scripts/verify-build.sh
```

#### [NEW] [git-workflow.sh](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/build-scripts/git-workflow.sh)
Pre-build Git automation:
```bash
#!/bin/bash
# Ensure working tree is clean or committed
# Tag build with version + commit hash
# Push to GitHub remote
```

#### [NEW] [download-v2ray.sh](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/build-scripts/download-v2ray.sh)
V2RAY core binary fetcher:
```bash
#!/bin/bash
# Download specific version of v2ray-core for macOS arm64
# Verify SHA256 checksum
# Extract binary to Resources/
```

#### [NEW] [create-dmg.sh](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/build-scripts/create-dmg.sh)
DMG packaging:
```bash
#!/bin/bash
# Use create-dmg or hdiutil
# Add background image, window positioning
# Include Applications symlink for drag-install
```

#### [NEW] [verify-build.sh](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/build-scripts/verify-build.sh)
Architecture & dependency verification:
```bash
#!/bin/bash
# file checks for arm64
# lipo -info verification
# otool -L for dynamic libraries
# codesign status check
```

---

### Component 5: Documentation

#### [NEW] [BUILD.md](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/BUILD.md)
Complete build guide:
- Prerequisites (Xcode, Conda, Git setup)
- Step-by-step build commands
- Environment setup instructions
- Directory structure explanation
- Versioning workflow

#### [NEW] [TROUBLESHOOTING.md](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/TROUBLESHOOTING.md)
Common issues:
- arm64 vs x86_64 architecture mismatches
- Missing dynamic libraries (libv2ray dependencies)
- Code signing failures
- Gatekeeper warnings and bypass methods
- V2RAY binary permissions
- Network extension loading issues

#### [NEW] [README.md](file:///Volumes/Daniel%20K1/Antigravity/V2RayUSA/README.md)
User-facing documentation:
- What the app does
- Installation instructions (drag DMG to Applications)
- First-time setup guide
- How to configure USA servers
- Astrill chaining setup

---

## Verification Plan

### Automated Build Verification

**Script**: `build-scripts/verify-build.sh`

```bash
# 1. Architecture verification
file build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA
# Expected: Mach-O 64-bit executable arm64

lipo -info build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA
# Expected: Non-fat file: arm64

# 2. V2RAY binary verification
file build/Build/Products/Release/V2RayUSA.app/Contents/Resources/v2ray-core
# Expected: Mach-O 64-bit executable arm64

# 3. Dynamic library check (should have minimal dependencies)
otool -L build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA
# Expected: Only system frameworks (Foundation, AppKit, SwiftUI, etc.)

# 4. Bundle structure check
ls -R build/Build/Products/Release/V2RayUSA.app/Contents/
# Verify: MacOS/, Resources/, Info.plist, _CodeSignature/ (if signed)

# 5. Code signature status
codesign -dv --verbose=4 build/Build/Products/Release/V2RayUSA.app
# If unsigned: "code object is not signed at all"
# If signed: shows certificate chain

# 6. DMG verification
hdiutil verify dist/V2RayUSA.dmg
# Expected: No errors
```

**Command to run**: 
```bash
cd /Volumes/Daniel\ K1/Antigravity/V2RayUSA
./build-scripts/verify-build.sh
```

### Manual Functional Testing

> [!NOTE]
> These tests require user interaction and cannot be automated.

**Test 1: Clean Machine Launch**
1. On a Mac without Xcode installed, mount `V2RayUSA.dmg`
2. Drag `V2RayUSA.app` to `/Applications`
3. Right-click → Open (first launch, bypass Gatekeeper)
4. **Expected**: App launches, menubar icon appears (no errors about missing libraries)

**Test 2: V2RAY Connection**
1. Open Preferences from menubar
2. Add USA server configuration (or use default if bundled)
3. Click "Connect" in menubar
4. **Expected**: Status changes to 🟢 Connected, V2RAY process running in Activity Monitor
5. Check internet traffic routes through USA server (visit ipinfo.io or similar)

**Test 3: Astrill Tunnel Chaining**
1. Connect to Astrill VPN first
2. Launch V2RayUSA and connect
3. Check routing: `netstat -rn | grep utun`
4. **Expected**: V2RAY traffic routes through Astrill interface
5. Verify IP shows USA location but traffic tunnels through Astrill

**Test 4: Disconnect & Cleanup**
1. Disconnect V2RayUSA
2. **Expected**: System proxy settings revert, v2ray process terminates
3. No orphaned processes in Activity Monitor

### Build Reproducibility Test

**Command**:
```bash
# Build 1
./build.sh
mv dist/V2RayUSA.dmg dist/V2RayUSA-build1.dmg

# Clean and rebuild
rm -rf build/
git checkout .
./build.sh
mv dist/V2RayUSA.dmg dist/V2RayUSA-build2.dmg

# Compare (DMGs will differ due to timestamps, but .app should be identical)
diff -r \
  dist/V2RayUSA-build1/ \
  dist/V2RayUSA-build2/
```

**Expected**: Identical `.app` bundles (except for build metadata timestamps).

### Git Workflow Verification

**Commands**:
```bash
# 1. Make a code change (e.g., update README.md)
echo "Test change" >> README.md

# 2. Run build (should fail if uncommitted)
./build.sh
# Expected: Script prompts to commit changes

# 3. Commit and retry
git add README.md
git commit -m "Test: verify Git workflow"
./build.sh
# Expected: Build succeeds, creates Git tag

# 4. Check GitHub remote
git push
git log --oneline -n 5
git tag
# Expected: Latest commit pushed, tag created (e.g., v1.0.0-abc1234)
```

---

## Additional Notes

- **V2RAY Version Pinning**: `download-v2ray.sh` will use a specific version (e.g., v5.20.0) with SHA256 verification to ensure reproducibility.
- **Icon Generation**: If no icon provided, I'll create a simple VPN-themed icon using the `generate_image` tool.
- **Security**: Server credentials will be stored in macOS Keychain, not plaintext files.
- **Logging**: App will write logs to `~/Library/Logs/V2RayUSA/` for debugging.
- **Updates**: Future enhancement—implement Sparkle framework for auto-updates.

