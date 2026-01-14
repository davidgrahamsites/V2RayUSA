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
        // Create menubar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "V2Ray")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create menu
        setupMenu()
        
        // Observer for connection status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusIcon),
            name: NSNotification.Name("V2RayConnectionStatusChanged"),
            object: nil
        )
        
        updateStatusIcon()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        v2rayManager.stopV2Ray()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Connection status
        let statusItem = NSMenuItem(
            title: v2rayManager.isConnected ? "🟢 Connected" : "🔴 Disconnected",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
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
        
        statusItem.menu = menu
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
                    button.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "V2Ray Connected")
                } else {
                    button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "V2Ray")
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
