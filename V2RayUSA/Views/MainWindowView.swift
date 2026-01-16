//
//  MainWindowView.swift
//  V2RayUSA
//
//  Beautiful main window UI with glassmorphism design
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var v2rayManager = V2RayManager.shared
    @StateObject private var configManager = ConfigManager.shared
    @State private var selectedConfig: ServerConfig
    @State private var showingPreferences = false
    @State private var showingLogs = false
    
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
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: v2rayManager.isConnected ? "lock.shield.fill" : "lock.shield")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            v2rayManager.isConnected ?
                                LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: v2rayManager.isConnected ? .green.opacity(0.5) : .blue.opacity(0.5), radius: 20)
                    
                    Text("V2RayUSA")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
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
                .padding(.top, 40)
                
                // Server Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server Configuration")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Server", value: selectedConfig.serverAddress)
                        InfoRow(label: "Port", value: "\(selectedConfig.port)")
                        InfoRow(label: "Protocol", value: selectedConfig.`protocol`.rawValue)
                        InfoRow(label: "Network", value: selectedConfig.network.rawValue)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Connect/Disconnect Button
                    Button(action: {
                        if v2rayManager.isConnected {
                            v2rayManager.stopV2Ray()
                        } else {
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
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    v2rayManager.isConnected ?
                                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .shadow(color: (v2rayManager.isConnected ? Color.red : Color.blue).opacity(0.5), radius: 20, y: 10)
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
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 500, height: 600)
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
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
            
            Button("Refresh") {
                loadLogs()
            }
            .buttonStyle(.borderedProminent)
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
            logs = "Unable to load logs from: \(logPath)"
        }
    }
}

#Preview {
    MainWindowView()
}
