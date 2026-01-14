//
//  PreferencesView.swift
//  V2RayUSA
//
//  Preferences window UI for server configuration
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var configManager = ConfigManager.shared
    @StateObject private var v2rayManager = V2RayManager.shared
    
    @State private var selectedConfig: ServerConfig
    @State private var configs: [ServerConfig] = []
    
    init() {
        let manager = ConfigManager.shared
        let loadedConfigs = manager.loadSavedConfigs() ?? []
        let defaultConfig = loadedConfigs.first ?? ServerConfig()
        _selectedConfig = State(initialValue: defaultConfig)
        _configs = State(initialValue: loadedConfigs.isEmpty ? [defaultConfig] : loadedConfigs)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("V2Ray Server Configuration")
                .font(.title2)
                .bold()
            
            Form {
                Section(header: Text("Server Details")) {
                    TextField("Server Name", text: $selectedConfig.name)
                    TextField("Server Address", text: $selectedConfig.serverAddress)
                    TextField("Port", value: $selectedConfig.port, format: .number)
                }
                
                Section(header: Text("Protocol")) {
                    Picker("Protocol", selection: $selectedConfig.protocol) {
                        ForEach(V2RayProtocol.allCases, id: \.self) { proto in
                            Text(proto.rawValue.uppercased()).tag(proto)
                        }
                    }
                    
                    TextField("User ID (UUID)", text: $selectedConfig.userId)
                        .font(.system(.body, design: .monospaced))
                    
                    TextField("Encryption", text: $selectedConfig.encryption)
                    
                    if selectedConfig.protocol == .vmess {
                        TextField("Alter ID", value: $selectedConfig.alterId, format: .number)
                    }
                }
                
                Section(header: Text("Network Settings")) {
                    Picker("Network Type", selection: $selectedConfig.network) {
                        ForEach(NetworkType.allCases, id: \.self) { net in
                            Text(net.rawValue.uppercased()).tag(net)
                        }
                    }
                    
                    if selectedConfig.network == .ws {
                        TextField("WebSocket Path", text: $selectedConfig.path)
                        TextField("Host Header (optional)", text: $selectedConfig.host)
                    }
                    
                    Toggle("Enable TLS", isOn: $selectedConfig.tls)
                }
            }
            
            HStack {
                Button("Save Configuration") {
                    configManager.saveConfig(selectedConfig)
                    
                    // Update V2Ray if connected
                    if v2rayManager.isConnected {
                        v2rayManager.stopV2Ray()
                        v2rayManager.currentConfig = selectedConfig
                        v2rayManager.startV2Ray()
                    } else {
                        v2rayManager.currentConfig = selectedConfig
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("View Logs") {
                    openLogsDirectory()
                }
                
                Button("Help") {
                    showHelp()
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Setup Instructions:")
                    .font(.headline)
                Text("1. Enter your V2Ray server address and port")
                    .font(.caption)
                Text("2. Paste your User ID (UUID from server)")
                    .font(.caption)
                Text("3. Configure network type (usually WebSocket for CDN)")
                    .font(.caption)
                Text("4. Enable TLS for secure connections")
                    .font(.caption)
                Text("5. Click 'Save Configuration' and use menubar to Connect")
                    .font(.caption)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 600, height: 550)
    }
    
    private func openLogsDirectory() {
        let logsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/V2RayUSA")
        NSWorkspace.shared.open(logsPath)
    }
    
    private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "V2RayUSA Help"
        alert.informativeText = """
        Server Configuration:
        - Get your server details from your V2Ray provider
        - UUID is a unique identifier for your account
        - WebSocket (ws) is recommended for better compatibility
        - Enable TLS if your server supports HTTPS
        
        Connection:
        - Use the menubar icon to Connect/Disconnect
        - Local SOCKS5 proxy runs on 127.0.0.1:1080
        - Logs are saved to ~/Library/Logs/V2RayUSA/
        
        Astrill Chaining:
        - Connect to Astrill first
        - Then connect V2RayUSA
        - Traffic will route: You → Astrill → V2Ray → Internet
        """
        alert.alertStyle = .informational
        alert.runModal()
    }
}

#Preview {
    PreferencesView()
}
