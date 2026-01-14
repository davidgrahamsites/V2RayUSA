//
//  ServerConfig.swift
//  V2RayUSA
//
//  Data models for V2Ray server configuration
//

import Foundation

enum V2RayProtocol: String, Codable, CaseIterable {
    case vmess = "vmess"
    case vless = "vless"
    case trojan = "trojan"
    case shadowsocks = "shadowsocks"
}

enum NetworkType: String, Codable, CaseIterable {
    case tcp = "tcp"
    case ws = "ws"
    case http = "http"
    case grpc = "grpc"
}

struct ServerConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var serverAddress: String
    var port: Int
    var `protocol`: V2RayProtocol
    var userId: String
    var alterId: Int
    var encryption: String
    var network: NetworkType
    var path: String
    var host: String
    var tls: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "USA Server",
        serverAddress: String = "your-server.example.com",
        port: Int = 443,
        protocol: V2RayProtocol = .vmess,
        userId: String = "YOUR-UUID-HERE",
        alterId: Int = 0,
        encryption: String = "auto",
        network: NetworkType = .ws,
        path: String = "/",
        host: String = "",
        tls: Bool = true
    ) {
        self.id = id
        self.name = name
        self.serverAddress = serverAddress
        self.port = port
        self.protocol = `protocol`
        self.userId = userId
        self.alterId = alterId
        self.encryption = encryption
        self.network = network
        self.path = path
        self.host = host
        self.tls = tls
    }
    
    // Convert to V2Ray JSON config format
    func toV2RayConfig() -> [String: Any] {
        return [
            "log": [
                "loglevel": "warning"
            ],
            "inbounds": [[
                "port": 1080,
                "protocol": "socks",
                "settings": [
                    "auth": "noauth",
                    "udp": true
                ]
            ]],
            "outbounds": [[
                "protocol": self.`protocol`.rawValue,
                "settings": [
                    "vnext": [[
                        "address": self.serverAddress,
                        "port": self.port,
                        "users": [[
                            "id": self.userId,
                            "alterId": self.alterId,
                            "security": self.encryption
                        ]]
                    ]]
                ],
                "streamSettings": [
                    "network": self.network.rawValue,
                    "security": self.tls ? "tls" : "none",
                    "wsSettings": self.network == .ws ? [
                        "path": self.path,
                        "headers": self.host.isEmpty ? [:] : ["Host": self.host]
                    ] : [:]
                ]
            ]]
        ]
    }
}
