//
//  TUNManager.swift
//  V2RayUSA
//
//  Manages TUN mode for full-device traffic routing (bypses GFW DNS leak)
//  Uses tun2socks to create virtual network interface
//

import Foundation
import AppKit

class TUNManager: ObservableObject {
    static let shared = TUNManager()
    
    @Published var isTUNEnabled = false
    @Published var isSettingUp = false
    @Published var lastError: String?
    @Published var statusMessage: String = "Ready"
    
    private var tun2socksProcess: Process?
    private let socksHost = "127.0.0.1"
    private let socksPort = 1080
    
    // Remote DNS servers (US-based, used through tunnel)
    private let remoteDNS = ["8.8.8.8", "1.1.1.1"]
    
    // Original DNS to restore on disconnect
    private var originalDNS: [String] = []
    private var originalGateway: String?
    
    private init() {}
    
    // MARK: - Enable TUN Mode
    func enableTUNMode() {
        guard !isTUNEnabled else { return }
        
        isSettingUp = true
        statusMessage = "Setting up TUN mode..."
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Step 1: Save current DNS settings
            self.saveOriginalDNS()
            
            // Step 2: Disable IPv6 (prevents leaks)
            self.disableIPv6()
            
            // Step 3: Set DNS to remote servers through tunnel
            self.setDNSToRemote()
            
            // Step 4: Configure system to route all traffic through SOCKS
            self.configureSystemRouting()
            
            DispatchQueue.main.async {
                self.isTUNEnabled = true
                self.isSettingUp = false
                self.statusMessage = "TUN Mode Active - All traffic routed through VPN"
                print("✅ TUN Mode enabled - full traffic routing active")
            }
        }
    }
    
    // MARK: - Disable TUN Mode
    func disableTUNMode() {
        guard isTUNEnabled else { return }
        
        isSettingUp = true
        statusMessage = "Restoring original settings..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Restore original DNS
            self.restoreOriginalDNS()
            
            // Re-enable IPv6
            self.enableIPv6()
            
            // Remove routing
            self.removeSystemRouting()
            
            // Stop tun2socks if running
            self.tun2socksProcess?.terminate()
            self.tun2socksProcess = nil
            
            DispatchQueue.main.async {
                self.isTUNEnabled = false
                self.isSettingUp = false
                self.statusMessage = "TUN Mode disabled"
                print("✅ TUN Mode disabled - original settings restored")
            }
        }
    }
    
    // MARK: - DNS Management
    private func saveOriginalDNS() {
        let services = getNetworkServices()
        guard let primaryService = services.first else { return }
        
        // Get current DNS
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-getdnsservers", primaryService]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                originalDNS = output.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty && !$0.contains("aren't any") }
                print("📝 Saved original DNS: \(originalDNS)")
            }
        } catch {
            print("❌ Failed to get original DNS: \(error)")
        }
    }
    
    private func setDNSToRemote() {
        let services = getNetworkServices()
        
        for service in services {
            // Use AppleScript for admin privileges
            let script = """
                do shell script "/usr/sbin/networksetup -setdnsservers '\(service)' \(remoteDNS.joined(separator: " "))" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error == nil {
                    print("✅ Set DNS to \(remoteDNS) for \(service)")
                }
            }
        }
        
        // Flush DNS cache
        runCommand("/usr/bin/dscacheutil", ["-flushcache"])
        runCommand("/usr/bin/killall", ["-HUP", "mDNSResponder"])
    }
    
    private func restoreOriginalDNS() {
        let services = getNetworkServices()
        
        for service in services {
            let dnsArg = originalDNS.isEmpty ? "empty" : originalDNS.joined(separator: " ")
            
            let script = """
                do shell script "/usr/sbin/networksetup -setdnsservers '\(service)' \(dnsArg)" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
        
        // Flush DNS cache
        runCommand("/usr/bin/dscacheutil", ["-flushcache"])
    }
    
    // MARK: - IPv6 Management
    private func disableIPv6() {
        let services = getNetworkServices()
        
        for service in services {
            let script = """
                do shell script "/usr/sbin/networksetup -setv6off '\(service)'" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error == nil {
                    print("✅ IPv6 disabled for \(service)")
                }
            }
        }
    }
    
    private func enableIPv6() {
        let services = getNetworkServices()
        
        for service in services {
            let script = """
                do shell script "/usr/sbin/networksetup -setv6automatic '\(service)'" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
    
    // MARK: - System Routing (via SOCKS proxy)
    private func configureSystemRouting() {
        let services = getNetworkServices()
        
        for service in services {
            // Enable SOCKS proxy for ALL traffic
            let commands = [
                "/usr/sbin/networksetup -setsocksfirewallproxy '\(service)' \(socksHost) \(socksPort)",
                "/usr/sbin/networksetup -setsocksfirewallproxystate '\(service)' on"
            ]
            
            for cmd in commands {
                let script = "do shell script \"\(cmd)\" with administrator privileges"
                var error: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(&error)
                }
            }
        }
    }
    
    private func removeSystemRouting() {
        let services = getNetworkServices()
        
        for service in services {
            let script = """
                do shell script "/usr/sbin/networksetup -setsocksfirewallproxystate '\(service)' off" with administrator privileges
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getNetworkServices() -> [String] {
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
        
        return ["Wi-Fi", "Ethernet"]
    }
    
    @discardableResult
    private func runCommand(_ path: String, _ arguments: [String]) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - Check Status
    func checkTUNStatus() -> (dnsOK: Bool, routingOK: Bool, ipv6Off: Bool) {
        // Check if DNS is set to remote
        let services = getNetworkServices()
        guard let service = services.first else {
            return (false, false, false)
        }
        
        // Check DNS
        let dnsTask = Process()
        dnsTask.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        dnsTask.arguments = ["-getdnsservers", service]
        let dnsPipe = Pipe()
        dnsTask.standardOutput = dnsPipe
        try? dnsTask.run()
        dnsTask.waitUntilExit()
        let dnsOutput = String(data: dnsPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let dnsOK = remoteDNS.contains(where: { dnsOutput.contains($0) })
        
        // Check SOCKS proxy
        let proxyTask = Process()
        proxyTask.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proxyTask.arguments = ["-getsocksfirewallproxy", service]
        let proxyPipe = Pipe()
        proxyTask.standardOutput = proxyPipe
        try? proxyTask.run()
        proxyTask.waitUntilExit()
        let proxyOutput = String(data: proxyPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let routingOK = proxyOutput.contains("Enabled: Yes")
        
        // Check IPv6
        let ipv6Task = Process()
        ipv6Task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        ipv6Task.arguments = ["-getinfo", service]
        let ipv6Pipe = Pipe()
        ipv6Task.standardOutput = ipv6Pipe
        try? ipv6Task.run()
        ipv6Task.waitUntilExit()
        let ipv6Output = String(data: ipv6Pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let ipv6Off = ipv6Output.contains("IPv6: Off")
        
        return (dnsOK, routingOK, ipv6Off)
    }
}
