//
//  main.swift
//  V2RayUSA
//
//  Traditional AppKit entry point for menubar-only app
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Activate app to ensure menubar item appears
app.setActivationPolicy(.accessory)  // This is key for menubar-only apps
app.activate(ignoringOtherApps: true)

app.run()
