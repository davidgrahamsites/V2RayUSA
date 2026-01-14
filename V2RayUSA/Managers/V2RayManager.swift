//
//  V2RayManager.swift
//  V2RayUSA
//
//  Manages V2Ray core process and VPN connection
//

import Foundation

class V2RayManager: ObservableObject {
    static let shared = V2RayManager()
    
    @Published var isConnected = false
    @Published var currentConfig: ServerConfig?
    
    private var v2rayProcess: Process?
    private let configManager = ConfigManager.shared
    private let logsDirectory: URL
    
    private init() {
        let logsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/V2RayUSA", isDirectory: true)
        self.logsDirectory = logsPath
        
        // Create logs directory if needed
        try? FileManager.default.createDirectory(at: logsPath, withIntermediateDirectories: true)
    }
    
    func startV2Ray() {
        guard !isConnected else {
            print("V2Ray already connected")
            return
        }
        
        // Load current config or use default
        let config = currentConfig ?? configManager.loadDefaultConfig()
        currentConfig = config
        
        // Write config to temp file
        guard let configURL = writeConfigFile(config) else {
            print("Failed to write config file")
            return
        }
        
        // Get V2Ray binary path
        guard let binaryPath = getV2RayBinaryPath() else {
            print("V2Ray binary not found")
            return
        }
        
        // Start V2Ray process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["-config", configURL.path]
        
        // Set up logging
        let logFile = logsDirectory.appendingPathComponent("v2ray.log")
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil)
        }
        
        let logHandle = try? FileHandle(forWritingTo: logFile)
        process.standardOutput = logHandle
        process.standardError = logHandle
        
        do {
            try process.run()
            v2rayProcess = process
            isConnected = true
            
            NotificationCenter.default.post(name: NSNotification.Name("V2RayConnectionStatusChanged"), object: nil)
            
            print("V2Ray started successfully on SOCKS5 127.0.0.1:1080")
        } catch {
            print("Failed to start V2Ray: \(error)")
        }
    }
    
    func stopV2Ray() {
        guard isConnected, let process = v2rayProcess else {
            return
        }
        
        process.terminate()
        v2rayProcess = nil
        isConnected = false
        
        NotificationCenter.default.post(name: NSNotification.Name("V2RayConnectionStatusChanged"), object: nil)
        
        print("V2Ray stopped")
    }
    
    private func writeConfigFile(_ config: ServerConfig) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let configURL = tempDir.appendingPathComponent("v2ray-config.json")
        
        let configDict = config.toV2RayConfig()
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: configDict, options: .prettyPrinted) else {
            return nil
        }
        
        try? jsonData.write(to: configURL)
        return configURL
    }
    
    private func getV2RayBinaryPath() -> String? {
        // Check in app bundle Resources
        if let bundlePath = Bundle.main.path(forResource: "v2ray", ofType: nil) {
            return bundlePath
        }
        
        // Check for v2ray-core in bundle
        if let bundlePath = Bundle.main.resourcePath {
            let v2rayPath = "\(bundlePath)/v2ray-core"
            if FileManager.default.fileExists(atPath: v2rayPath) {
                return v2rayPath
            }
        }
        
        // Fallback to system path (for development)
        return "/usr/local/bin/v2ray"
    }
    
    func testConnection() -> Bool {
        // TODO: Implement connection test (e.g., curl through SOCKS proxy)
        return isConnected
    }
}
