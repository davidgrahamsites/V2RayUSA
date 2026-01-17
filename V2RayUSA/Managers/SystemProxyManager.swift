//
//  SystemProxyManager.swift
//  V2RayUSA
//
//  Manages macOS system-wide proxy settings to route all traffic through V2Ray
//

import Foundation
import AppKit

class SystemProxyManager: ObservableObject {
    static let shared = SystemProxyManager()
    
    @Published var isSystemProxyEnabled = false
    @Published var lastError: String?
    
    private let proxyHost = "127.0.0.1"
    private let socksPort = 1080
    private let httpPort = 1087  // V2Ray can also provide HTTP proxy
    
    // Get all network services (Wi-Fi, Ethernet, etc.)
    func getNetworkServices() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-listallnetworkservices"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: "\n")
                    .filter { !$0.isEmpty && !$0.contains("*") }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }
        } catch {
            print("❌ Failed to get network services: \(error)")
        }
        
        return ["Wi-Fi", "Ethernet"]  // Fallback defaults
    }
    
    // Enable system-wide SOCKS proxy
    func enableSystemProxy() {
        let services = getNetworkServices()
        var success = true
        
        for service in services {
            // Enable SOCKS proxy
            if !runNetworkSetup(["-setsocksfirewallproxy", service, proxyHost, "\(socksPort)"]) {
                success = false
            }
            if !runNetworkSetup(["-setsocksfirewallproxystate", service, "on"]) {
                success = false
            }
            
            print("✅ Enabled SOCKS proxy for: \(service)")
        }
        
        DispatchQueue.main.async {
            self.isSystemProxyEnabled = success
            if success {
                self.lastError = nil
                print("🌐 System-wide proxy ENABLED - all traffic now routes through V2Ray")
            } else {
                self.lastError = "Failed to enable proxy for some services"
            }
        }
    }
    
    // Disable system-wide SOCKS proxy
    func disableSystemProxy() {
        let services = getNetworkServices()
        
        for service in services {
            runNetworkSetup(["-setsocksfirewallproxystate", service, "off"])
            print("✅ Disabled SOCKS proxy for: \(service)")
        }
        
        DispatchQueue.main.async {
            self.isSystemProxyEnabled = false
            self.lastError = nil
            print("🌐 System-wide proxy DISABLED")
        }
    }
    
    // Toggle system proxy
    func toggleSystemProxy() {
        if isSystemProxyEnabled {
            disableSystemProxy()
        } else {
            enableSystemProxy()
        }
    }
    
    // Run networksetup command (may require admin privileges)
    @discardableResult
    private func runNetworkSetup(_ arguments: [String]) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("❌ networksetup failed: \(error)")
            return false
        }
    }
    
    // Enable with admin privileges using AppleScript
    func enableSystemProxyWithAdmin() {
        let services = getNetworkServices()
        var commands: [String] = []
        
        for service in services {
            commands.append("do shell script \"/usr/sbin/networksetup -setsocksfirewallproxy '\(service)' \(proxyHost) \(socksPort)\" with administrator privileges")
            commands.append("do shell script \"/usr/sbin/networksetup -setsocksfirewallproxystate '\(service)' on\" with administrator privileges")
        }
        
        let script = commands.joined(separator: "\n")
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            
            DispatchQueue.main.async {
                if error == nil {
                    self.isSystemProxyEnabled = true
                    self.lastError = nil
                    print("✅ System proxy enabled with admin privileges")
                } else {
                    self.lastError = "Failed to enable proxy: \(error?["NSAppleScriptErrorMessage"] ?? "Unknown error")"
                    print("❌ AppleScript error: \(String(describing: error))")
                }
            }
        }
    }
    
    // Disable with admin privileges
    func disableSystemProxyWithAdmin() {
        let services = getNetworkServices()
        var commands: [String] = []
        
        for service in services {
            commands.append("do shell script \"/usr/sbin/networksetup -setsocksfirewallproxystate '\(service)' off\" with administrator privileges")
        }
        
        let script = commands.joined(separator: "\n")
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            
            DispatchQueue.main.async {
                self.isSystemProxyEnabled = false
                if error != nil {
                    self.lastError = "Warning: Some services may not have been updated"
                } else {
                    self.lastError = nil
                }
            }
        }
    }
    
    // Check current proxy status
    func checkProxyStatus() {
        let services = getNetworkServices()
        guard let firstService = services.first else { return }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-getsocksfirewallproxy", firstService]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let isEnabled = output.contains("Enabled: Yes")
                let isOurProxy = output.contains("Server: \(proxyHost)") && output.contains("Port: \(socksPort)")
                
                DispatchQueue.main.async {
                    self.isSystemProxyEnabled = isEnabled && isOurProxy
                }
            }
        } catch {
            print("❌ Failed to check proxy status: \(error)")
        }
    }
}
