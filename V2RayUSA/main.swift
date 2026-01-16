//
//  main.swift
//  V2RayUSA
//
//  Traditional AppKit entry point with window + menubar support
//

import AppKit
import SwiftUI

// Setup logging to file for debugging
func setupDebugLogging() {
    let logDir = NSHomeDirectory() + "/Library/Logs/V2RayUSA"
    try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
    let logPath = logDir + "/debug.log"
    
    freopen(logPath.cString(using: .utf8), "a+", stdout)
    freopen(logPath.cString(using: .utf8), "a+", stderr)
    
    print("\n" + String(repeating: "=", count: 60))
    print("V2RayUSA Launch - \(Date())")
    print(String(repeating: "=", count: 60))
}

setupDebugLogging()
print("🚀 V2RayUSA: Starting application...")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Use .regular activation policy to show window AND menubar
// (Change to .accessory to hide from Dock once menubar is working)
app.setActivationPolicy(.regular)
print("📍 V2RayUSA: Set activation policy to .regular (windowed mode)")

app.activate(ignoringOtherApps: true)
print("✅ V2RayUSA: App activated")

// Create and show main window
let mainView = MainWindowView()
let hostingController = NSHostingController(rootView: mainView)
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.title = "V2RayUSA"
window.contentViewController = hostingController
window.center()
window.makeKeyAndOrderFront(nil)
window.isReleasedWhenClosed = false

print("🪟 V2RayUSA: Main window created and displayed")

app.run()
print("👋 V2RayUSA: App terminated")
