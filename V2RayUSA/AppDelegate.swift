//
//  AppDelegate.swift
//  V2RayUSA
//
//  Manages menubar and application lifecycle
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var v2rayManager = V2RayManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 V2RayUSA: applicationDidFinishLaunching called")
        
        // Create menubar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("📍 V2RayUSA: statusItem created: \(statusItem != nil)")
        
        if let button = statusItem.button {
            button.title = "🔒"  // Use emoji instead of SF Symbol for better compatibility
            button.action = #selector(togglePopover)
            button.target = self
            print("✅ V2RayUSA: button configured with title")
        } else {
            print("❌ V2RayUSA: statusItem.button is nil!")
        }
        
        // Create menu
        setupMenu()
        print("✅ V2RayUSA: menu setup complete")
        
        // Observer for connection status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusIcon),
            name: NSNotification.Name("V2RayConnectionStatusChanged"),
            object: nil
        )
        
        updateStatusIcon()
        print("✅ V2RayUSA: initialization complete - menubar icon should be visible")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        v2rayManager.stopV2Ray()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Connection status
        let statusMenuItem = NSMenuItem(
            title: v2rayManager.isConnected ? "🟢 Connected" : "🔴 Disconnected",
            action: nil,
            keyEquivalent: ""
        )
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Connect/Disconnect toggle
        let connectItem = NSMenuItem(
            title: v2rayManager.isConnected ? "Disconnect" : "Connect",
            action: #selector(toggleConnection),
            keyEquivalent: "c"
        )
        connectItem.target = self
        menu.addItem(connectItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit V2RayUSA",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem.menu = menu
    }
    
    @objc private func togglePopover() {
        // Menu is shown automatically when clicking status item
    }
    
    @objc private func toggleConnection() {
        if v2rayManager.isConnected {
            v2rayManager.stopV2Ray()
        } else {
            v2rayManager.startV2Ray()
        }
        setupMenu() // Refresh menu
    }
    
    @objc private func openPreferences() {
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "V2RayUSA Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 600, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func updateStatusIcon() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let button = self.statusItem.button {
                if self.v2rayManager.isConnected {
                    button.title = "🔓"  // Open lock when connected
                } else {
                    button.title = "🔒"  // Closed lock when disconnected
                }
            }
            self.setupMenu()
        }
    }
    
    @objc private func quitApp() {
        v2rayManager.stopV2Ray()
        NSApplication.shared.terminate(self)
    }
}
