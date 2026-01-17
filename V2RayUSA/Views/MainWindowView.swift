//
//  MainWindowView.swift
//  V2RayUSA
//
//  Beautiful main window UI with glassmorphism design and server import
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var v2rayManager = V2RayManager.shared
    @StateObject private var configManager = ConfigManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var systemProxyManager = SystemProxyManager.shared
    @State private var selectedConfig: ServerConfig
    @State private var showingPreferences = false
    @State private var showingLogs = false
    @State private var selectedSourceIndex = 0
    @State private var routingMode: RoutingMode = .normal
    
    enum RoutingMode: String, CaseIterable {
        case normal = "Normal"
        case systemProxy = "System Proxy"
        case tunMode = "TUN Mode"
        
        var description: String {
            switch self {
            case .normal: return "SOCKS5 proxy on localhost:1080 - Apps must be configured manually"
            case .systemProxy: return "Routes most traffic via macOS system settings"
            case .tunMode: return "Routes ALL traffic including system apps (requires tun2socks)"
            }
        }
        
        var icon: String {
            switch self {
            case .normal: return "network"
            case .systemProxy: return "globe"
            case .tunMode: return "shield.checkered"
            }
        }
    }
    
    init() {
        _selectedConfig = State(initialValue: ConfigManager.shared.loadDefaultConfig())
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)), Color(#colorLiteral(red: 0.05, green: 0.05, blue: 0.15, alpha: 1))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Server Import Section
                    serverImportSection
                    
                    // Server Selection
                    if !subscriptionManager.servers.isEmpty {
                        serverSelectionSection
                    }
                    
                    // Current Server Info
                    serverInfoSection
                    
                    // System-Wide Proxy Toggle
                    systemProxySection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 30)
            }
        }
        .frame(minWidth: 520, minHeight: 750)
        .onAppear {
            systemProxyManager.checkProxyStatus()
        }
    }
    
    // MARK: - Routing Mode Section
    var systemProxySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🌍 Routing Mode")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Current mode indicator
                HStack(spacing: 6) {
                    Image(systemName: routingMode.icon)
                        .foregroundColor(routingMode == .normal ? .gray : .green)
                    Text(routingMode.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // 3-way Segmented Picker
            HStack(spacing: 0) {
                makeModeButton(.normal)
                makeModeButton(.systemProxy)
                makeModeButton(.tunMode)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Description
            Text(routingMode.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            
            // Status/Warnings
            if !v2rayManager.isConnected && routingMode != .normal {
                Text("⚠️ Connect to a server first to apply this routing mode")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            if routingMode == .tunMode {
                Text("ℹ️ TUN mode requires tun2socks binary. Will download if not found.")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if let error = systemProxyManager.lastError {
                Text("❌ \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(routingMode != .normal ? Color.green.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    func modeColor(_ mode: RoutingMode) -> LinearGradient {
        switch mode {
        case .normal:
            return LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .systemProxy:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        case .tunMode:
            return LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    func applyRoutingMode(_ mode: RoutingMode) {
        // First disable current mode
        if routingMode == .systemProxy {
            systemProxyManager.disableSystemProxy()
        }
        // TODO: disable TUN mode if active
        
        routingMode = mode
        
        // Apply new mode if connected
        guard v2rayManager.isConnected else { return }
        
        switch mode {
        case .normal:
            // Just SOCKS5, no system-wide routing
            break
        case .systemProxy:
            systemProxyManager.enableSystemProxyWithAdmin()
        case .tunMode:
            // TODO: Start tun2socks
            systemProxyManager.lastError = "TUN mode coming soon - system proxy applied for now"
            systemProxyManager.enableSystemProxyWithAdmin()
        }
    }
    
    @ViewBuilder
    func makeModeButton(_ mode: RoutingMode) -> some View {
        let isSelected = routingMode == mode
        Button(action: {
            applyRoutingMode(mode)
        }) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.title3)
                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8).fill(modeColor(mode))
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: v2rayManager.isConnected ? "lock.shield.fill" : "lock.shield")
                .font(.system(size: 50))
                .foregroundStyle(
                    v2rayManager.isConnected ?
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: v2rayManager.isConnected ? .green.opacity(0.5) : .blue.opacity(0.5), radius: 15)
            
            Text("V2RayUSA")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Status Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(v2rayManager.isConnected ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                    .shadow(color: v2rayManager.isConnected ? .green : .clear, radius: 5)
                
                Text(v2rayManager.isConnected ? "Connected" : "Disconnected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Server Import Section
    var serverImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌐 Import Public Servers")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                // Source Picker
                Picker("Source", selection: $selectedSourceIndex) {
                    ForEach(0..<subscriptionManager.subscriptionSources.count, id: \.self) { index in
                        Text(subscriptionManager.subscriptionSources[index].name)
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Fetch Button
                Button(action: {
                    subscriptionManager.fetchServers(from: selectedSourceIndex, limit: 30)
                }) {
                    HStack(spacing: 6) {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text("Fetch")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
                .disabled(subscriptionManager.isLoading)
            }
            
            if let error = subscriptionManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if !subscriptionManager.servers.isEmpty {
                Text("✅ Found \(subscriptionManager.servers.count) servers")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Server Selection Section
    var serverSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📡 Select Server")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            Menu {
                ForEach(subscriptionManager.servers) { server in
                    Button(action: {
                        selectedConfig = server
                        configManager.saveConfig(server)
                    }) {
                        Text("\(server.`protocol`.rawValue.uppercased()) - \(server.name)")
                    }
                }
            } label: {
                HStack {
                    Text(selectedConfig.name)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Server Info Section
    var serverInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ Current Configuration")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Name", value: selectedConfig.name)
                InfoRow(label: "Server", value: selectedConfig.serverAddress)
                InfoRow(label: "Port", value: "\(selectedConfig.port)")
                InfoRow(label: "Protocol", value: selectedConfig.`protocol`.rawValue.uppercased())
                InfoRow(label: "Network", value: selectedConfig.network.rawValue)
                InfoRow(label: "TLS", value: selectedConfig.tls ? "✓ Enabled" : "✗ Disabled")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons Section
    var actionButtonsSection: some View {
        VStack(spacing: 14) {
            // Connect/Disconnect Button
            Button(action: {
                if v2rayManager.isConnected {
                    v2rayManager.stopV2Ray()
                    // Also disable system proxy if active
                    if routingMode != .normal {
                        systemProxyManager.disableSystemProxy()
                        routingMode = .normal
                    }
                } else {
                    // Pass selected config to V2RayManager
                    v2rayManager.currentConfig = selectedConfig
                    configManager.saveConfig(selectedConfig)
                    v2rayManager.startV2Ray()
                }
            }) {
                HStack {
                    Image(systemName: v2rayManager.isConnected ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(v2rayManager.isConnected ? "Disconnect" : "Connect")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            v2rayManager.isConnected ?
                                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: (v2rayManager.isConnected ? Color.red : Color.blue).opacity(0.4), radius: 15, y: 8)
                )
            }
            .buttonStyle(.plain)
            
            // Secondary Actions
            HStack(spacing: 12) {
                SecondaryButton(icon: "gearshape.fill", title: "Settings") {
                    showingPreferences = true
                }
                
                SecondaryButton(icon: "doc.text.fill", title: "Logs") {
                    showingLogs = true
                }
                
                SecondaryButton(icon: "xmark.circle.fill", title: "Quit") {
                    v2rayManager.stopV2Ray()
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
                .frame(width: 600, height: 500)
        }
        .sheet(isPresented: $showingLogs) {
            LogsView()
                .frame(width: 700, height: 500)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

struct SecondaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct LogsView: View {
    @State private var logs: String = "Loading logs..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("V2Ray Logs")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                Text(logs)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            HStack {
                Button("Refresh") {
                    loadLogs()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            loadLogs()
        }
    }
    
    func loadLogs() {
        let logPath = NSHomeDirectory() + "/Library/Logs/V2RayUSA/v2ray.log"
        if let logContent = try? String(contentsOfFile: logPath) {
            logs = logContent.isEmpty ? "No logs yet" : logContent
        } else {
            logs = "Unable to load logs from: \(logPath)\n\nLogs will appear here once you connect to a server."
        }
    }
}

#Preview {
    MainWindowView()
}
