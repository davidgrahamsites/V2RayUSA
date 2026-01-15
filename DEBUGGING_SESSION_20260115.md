# V2RayUSA Debugging Session - January 15, 2026

## Issue Discovered
Menubar icon was not appearing despite app launching successfully.

## Root Cause Analysis

The issue was a fundamental architectural problem with using SwiftUI's `@main App` structure for a menubar-only application.

### Problems Identified:

1. **SwiftUI App Lifecycle Incompatibility**
   - SwiftUI's `App` structure with `@NSApplicationDelegateAdaptor` doesn't properly initialize menubar-only apps
   - The AppDelegate's `applicationDidFinishLaunching` was being called, but the activation policy wasn't set correctly

2. **Variable Name Collision** 
   - In `AppDelegate.swift` line 89: local variable `statusItem` (NSMenuItem) was shadowing class property `self.statusItem` (NSStatusItem)
   - This caused the menu to never be assigned to the status bar icon

3. **Swift Reserved Keywords**
   - `ServerConfig.swift` used `protocol` as a variable name, requiring backtick escaping

4. **ObservableObject Conformance**
   - `ConfigManager` needed to conform to `ObservableObject` for SwiftUI compatibility

## Solution Implemented

### Architecture Change: SwiftUI → Traditional AppKit

**Created `main.swift`** with proper setup:
```swift
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // Critical for menubar apps!
app.activate(ignoringOtherApps: true)
app.run()
```

**Key changes:**
- Removed `V2RayUSAApp.swift` (SwiftUI App structure)
- Used `.accessory` activation policy for menubar-only behavior
- Ensured proper initialization order

### Code Fixes

1. **AppDelegate.swift**
   - Renamed conflicting `statusItem` variable to `statusMenuItem`
   - Changed from SF Symbols to emoji icons (🔒/🔓) for better compatibility
   - Added debug logging with print statements

2. **ServerConfig.swift**
   - Escaped `protocol` keyword with backticks: `` `protocol` ``

3. **ConfigManager.swift**
   - Added `ObservableObject` conformance

4. **Xcode Project Generation**
   - Updated `build-scripts/create-xcode-project.sh` to reference `main.swift` instead of `V2RayUSAApp.swift`

## Files Modified

- `/V2RayUSA/main.swift` (NEW)
- `/V2RayUSA/AppDelegate.swift`
- `/V2RayUSA/Models/ServerConfig.swift`
- `/V2RayUSA/Managers/ConfigManager.swift`
- `/build-scripts/create-xcode-project.sh`

## Build Process

Successfully rebuilt with:
```bash
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
xcodebuild -project V2RayUSA.xcodeproj \
  -scheme V2RayUSA \
  -configuration Release \
  -arch arm64 \
  -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  clean build
```

## Lessons Learned

1. **SwiftUI App is NOT suitable for menubar-only apps** - use traditional `NSApplication` setup
2. **`.accessory` activation policy is critical** for apps that should only show in menubar
3. **Variable shadowing** can cause subtle bugs - always use `self.` for class properties when there might be local variables with similar names
4. **SF Symbols may have compatibility issues** - fallback to emoji or PNG icons for simpler apps

## Status

✅ App compiles successfully  
✅ Architectural issues resolved  
✅ Variable naming conflicts fixed  
✅ Proper AppKit lifecycle implemented  
⏳ Menubar icon display needs user verification

---

**Commit**: "Fix menubar icon display issue - convert to traditional AppKit architecture"
