# V2RayUSA - Troubleshooting Guide

Common issues, error messages, and solutions for building and running V2RayUSA.

## Build Issues

### 1. "xcodebuild: command not found"

**Problem**: Xcode command-line tools not installed.

**Solution**:
```bash
xcode-select --install
```

Wait for installation to complete, then retry build.

---

### 2. "error: Signing for 'V2RayUSA' requires a development team"

**Problem**: Xcode trying to sign the app but no team configured.

**Solution**:
Edit `build-scripts/create-xcode-project.sh`, find this line:
```
CODE_SIGN_IDENTITY = "-";
```

Ensure it's set to `"-"` (dash in quotes) to disable signing.

Or manually in Xcode:
1. Open `V2RayUSA.xcodeproj`
2. Select target → Signing & Capabilities
3. Uncheck "Automatically manage signing"
4. Set "Code Signing Identity" to "n/a"

---

### 3. V2Ray Binary Architecture Mismatch

**Error**: 
```
❌ V2Ray binary is NOT arm64!
```

**Problem**: Downloaded wrong V2Ray binary (Intel instead of ARM).

**Solution**:
```bash
# Remove incorrect binary
rm V2RayUSA/Resources/v2ray

# Re-download correct version
./build-scripts/download-v2ray.sh

# Verify
file V2RayUSA/Resources/v2ray
# Should show: Mach-O 64-bit executable arm64
```

---

### 4. "Build input file cannot be found"

**Problem**: Source files moved or Xcode project out of sync.

**Solution**:
```bash
# Regenerate Xcode project
./build-scripts/create-xcode-project.sh

# Rebuild
xcodebuild -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  clean build
```

---

### 5. Git Workflow Fails - "no remote 'origin'"

**Error**:
```
⚠️  Could not push to remote (branch may not exist)
```

**Problem**: GitHub remote not configured.

**Solution**:
```bash
# Add GitHub remote
git remote add origin https://github.com/yourusername/v2rayusa.git

# Push
git push -u origin main

# Retry build
./build-scripts/build.sh
```

If you don't want GitHub integration:
Edit `build-scripts/git-workflow.sh` and comment out push commands.

---

## Runtime Issues

### 6. "V2RayUSA can't be opened because it is from an unidentified developer"

**Problem**: macOS Gatekeeper blocking unsigned app.

**Solution**:
1. **Don't double-click the app**
2. **Right-click** → **Open**
3. Click **Open** in dialog
4. App will open and be remembered

Alternative:
```bash
xattr -d com.apple.quarantine /Applications/V2RayUSA.app
```

---

### 7. App Opens But "V2Ray binary not found"

**Problem**: V2Ray core not bundled in app.

**Diagnosis**:
```bash
# Check if binary exists
ls -la build/Build/Products/Release/V2RayUSA.app/Contents/Resources/v2ray
```

**Solution if missing**:
```bash
# Download V2Ray
./build-scripts/download-v2ray.sh

# Rebuild app
xcodebuild -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  clean build
```

---

### 8. Connection Fails - "Failed to start V2Ray"

**Problem**: Various causes - check logs first.

**Diagnosis**:
```bash
# View logs
cat ~/Library/Logs/V2RayUSA/v2ray.log

# Or from app: Preferences → View Logs
```

**Common log errors**:

**Error: "config file not found"**
- Server config not saved
- Solution: Open Preferences, enter server details, click Save

**Error: "failed to dial"**
- Server address unreachable
- Solution: Check server address, port, firewall

**Error: "invalid UUID"**
- User ID format wrong
- Solution: UUID must be format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

**Error: "certificate verification failed"**
- TLS cert mismatch
- Solution: If using domain, ensure Host field matches certificate

---

### 9. Connected But No Internet

**Problem**: System not using V2Ray proxy.

**V2Ray runs on**: `127.0.0.1:1080` (SOCKS5)

**Solution Option 1 - System Proxy**:
1. System Preferences → Network
2. Select your connection → Advanced → Proxies
3. Check "SOCKS Proxy"
4. Server: `127.0.0.1`, Port: `1080`
5. Click OK, Apply

**Solution Option 2 - Browser Extension**:
- Install SwitchyOmega (Chrome/Edge) or FoxyProxy (Firefox)
- Configure SOCKS5 proxy: `127.0.0.1:1080`
- Toggle proxy on

**Solution Option 3 - CLI**:
```bash
# Test proxy with curl
curl --socks5 127.0.0.1:1080 https://ipinfo.io

# Should show your VPN server's IP
```

---

### 10. App Crashes on Launch

**Diagnosis**:
```bash
# Check crash logs
open ~/Library/Logs/DiagnosticReports/

# Look for V2RayUSA crash reports
```

**Common causes**:

**Missing Swift runtime**:
- Rare on modern macOS, but check:
```bash
otool -L /Applications/V2RayUSA.app/Contents/MacOS/V2RayUSA | grep swift
```
- Should show `@rpath/libswiftCore.dylib` (bundled)

**Corrupted preferences**:
```bash
# Reset preferences
defaults delete com.v2rayusa.app
rm -rf ~/Library/Preferences/com.v2rayusa.app.plist
```

---

### 11. Astrill Chaining Not Working

**Problem**: Traffic not routing through both VPNs.

**Diagnosis**:
```bash
# Check active VPN interfaces
ifconfig | grep utun

# Check routing table
netstat -rn
```

**Solution**:
1. **Connect Astrill first** - wait for "Connected" status
2. **Then connect V2RayUSA**
3. Check IP:
   ```bash
   curl --socks5 127.0.0.1:1080 https://ipinfo.io
   ```
   Should show USA location (V2Ray server)

If still not working:
- Ensure Astrill is in "VPN mode" (not "Smart mode")
- Check Astrill isn't blocking local SOCKS proxy
- Try disconnecting both and reconnecting in order

---

### 12. High CPU Usage

**Problem**: V2Ray process using excessive CPU.

**Diagnosis**:
```bash
# Check process
ps aux | grep v2ray

# Monitor resources
open -a "Activity Monitor"
# Search for "v2ray"
```

**Solutions**:
- Outdated server config - try different encryption (e.g., `none` instead of `aes-128-gcm`)
- Network type issues - try TCP instead of WebSocket
- Server overload - try different server

---

## DMG / Distribution Issues

### 13. DMG Won't Mount

**Error**: "image not recognized"

**Solution**:
```bash
# Verify DMG
hdiutil verify dist/V2RayUSA.dmg

# If corrupted, recreate
rm dist/V2RayUSA.dmg
./build-scripts/create-dmg.sh
```

---

### 14. Users Can't Install - "No Permission"

**Problem**: Security & Privacy settings blocking.

**User solution**:
1. System Settings → Privacy & Security
2. Scroll to "Security" section
3. Click "Allow Anyway" next to V2RayUSA message
4. Right-click app → Open

---

## Architecture Issues

### 15. "Bad CPU type in executable" on Intel Mac

**Problem**: App built for arm64, running on Intel Mac.

**This is expected** - app is arm64-only.

**Solution for Intel support**:
Edit `build-scripts/create-xcode-project.sh`:
```diff
- ARCHS = arm64;
+ ARCHS = "arm64 x86_64";
```

Then rebuild. This creates universal binary (larger file size).

---

### 16. Rosetta Translation Issues

**Problem**: Running arm64 app via Rosetta.

**Don't do this** - Rosetta is Intel→ARM, not ARM→Intel.

**Verify your Mac**:
```bash
uname -m
# arm64 = Apple Silicon ✅
# x86_64 = Intel (app won't run) ❌
```

---

## Network Issues

### 17. Firewall Blocking V2Ray

**Problem**: macOS Firewall blocking connections.

**Solution**:
1. System Preferences → Security & Privacy → Firewall
2. Click Firewall Options
3. Add V2RayUSA to allowed apps
4. Allow incoming connections

---

### 18. DNS Leaks

**Problem**: DNS queries not going through VPN.

**Diagnosis**:
```bash
# Check DNS servers
scutil --dns

# Online test
open https://dnsleaktest.com
```

**Solution**:
Configure DNS in V2Ray config (advanced):
- Use DoH (DNS over HTTPS): `1.1.1.1`, `8.8.8.8`
- Or use Astrill's DNS if chaining

---

## Development Issues

### 19. Xcode Project Won't Open

**Error**: "The project 'V2RayUSA' is damaged"

**Solution**:
```bash
# Regenerate project
rm -rf V2RayUSA.xcodeproj
./build-scripts/create-xcode-project.sh
```

---

### 20. Changes Not Reflected After Rebuild

**Problem**: Xcode caching old build.

**Solution**:
```bash
# Clean derived data
rm -rf build/

# Full clean rebuild
xcodebuild -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  clean build
```

---

## Getting More Help

### Enable Debug Logging

Edit `V2RayUSA/Models/ServerConfig.swift`:
```swift
"log": [
-   "loglevel": "warning"
+   "loglevel": "debug"
]
```

Rebuild, run, check logs at `~/Library/Logs/V2RayUSA/v2ray.log`.

### Useful Commands

```bash
# Verify app bundle
codesign -dv build/Build/Products/Release/V2RayUSA.app

# Check dependencies
otool -L build/Build/Products/Release/V2RayUSA.app/Contents/MacOS/V2RayUSA

# Test SOCKS proxy
curl --socks5 127.0.0.1:1080 https://ipinfo.io

# Monitor V2Ray process
sudo fs_usage | grep v2ray
```

### Report an Issue

When reporting bugs, include:
1. macOS version: `sw_vers`
2. App version: Check Info.plist
3. Build logs
4. V2Ray logs: `~/Library/Logs/V2RayUSA/v2ray.log`
5. Steps to reproduce

---

**Still stuck?** Open an issue on GitHub with logs and error messages.
