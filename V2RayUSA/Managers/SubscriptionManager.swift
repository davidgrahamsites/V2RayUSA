//
//  SubscriptionManager.swift
//  V2RayUSA
//
//  Fetches and parses V2Ray subscription configs from public sources
//

import Foundation

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var servers: [ServerConfig] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    // Public subscription sources
    let subscriptionSources: [(name: String, url: String)] = [
        ("Epodonios VMess", "https://raw.githubusercontent.com/Epodonios/v2ray-configs/main/Splitted-By-Protocol/vmess.txt"),
        ("Epodonios VLESS", "https://raw.githubusercontent.com/Epodonios/v2ray-configs/main/Splitted-By-Protocol/vless.txt"),
        ("Barry-Far All", "https://raw.githubusercontent.com/barry-far/V2ray-Configs/main/Sub1.txt"),
        ("Barry-Far Sub2", "https://raw.githubusercontent.com/barry-far/V2ray-Configs/main/Sub2.txt"),
    ]
    
    init() {
        // Load fallback servers immediately so app works without network
        loadFallbackServers()
    }
    
    // Fallback servers loaded on init (GFW blocks GitHub fetch)
    func loadFallbackServers() {
        // Real pre-loaded servers from vmess:// URIs
        let fallbackConfigs: [ServerConfig] = [
            ServerConfig(
                name: "Tel: @free_vmess1",
                serverAddress: "159.69.102.131",
                port: 8080,
                protocol: .vmess,
                userId: "3c67bb79-8b96-43d1-c576-c01dff9178ff",
                alterId: 0,
                encryption: "auto",
                network: .ws,
                path: "/",
                host: "Bmi.ir",
                tls: false
            ),
            ServerConfig(
                name: "V2Ray Vmess-US-11069242",
                serverAddress: "104.238.162.76",
                port: 20086,
                protocol: .vmess,
                userId: "6cf93fe6-0062-4212-95aa-2aabca8b11bf",
                alterId: 0,
                encryption: "auto",
                network: .ws,
                path: "/",
                host: "",
                tls: false
            ),
        ]
        
        servers = fallbackConfigs
        print("✅ Pre-loaded \(fallbackConfigs.count) working server(s) - ready to connect!")
    }
    
    func fetchServers(from sourceIndex: Int = 0, limit: Int = 20) {
        guard sourceIndex < subscriptionSources.count else { return }
        
        let source = subscriptionSources[sourceIndex]
        guard let url = URL(string: source.url) else { return }
        
        isLoading = true
        lastError = nil
        
        print("📡 Fetching servers from: \(source.name)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.lastError = "Network error: \(error.localizedDescription)"
                    print("❌ Fetch error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data, let content = String(data: data, encoding: .utf8) else {
                    self?.lastError = "Failed to decode response"
                    return
                }
                
                let configs = self?.parseSubscriptionContent(content, limit: limit) ?? []
                self?.servers = configs
                print("✅ Parsed \(configs.count) server configs")
            }
        }.resume()
    }
    
    private func parseSubscriptionContent(_ content: String, limit: Int) -> [ServerConfig] {
        var configs: [ServerConfig] = []
        let lines = content.components(separatedBy: CharacterSet.newlines)
        
        for line in lines {
            guard configs.count < limit else { break }
            
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            if let config = parseV2RayURI(trimmed) {
                configs.append(config)
            }
        }
        
        return configs
    }
    
    func parseV2RayURI(_ uri: String) -> ServerConfig? {
        if uri.hasPrefix("vmess://") {
            return parseVMessURI(uri)
        } else if uri.hasPrefix("vless://") {
            return parseVLessURI(uri)
        } else if uri.hasPrefix("trojan://") {
            return parseTrojanURI(uri)
        } else if uri.hasPrefix("ss://") {
            return parseShadowsocksURI(uri)
        }
        return nil
    }
    
    // Parse individual vmess:// URI - made public for manual paste feature
    public func parseVMessURI(_ uri: String) -> ServerConfig? {
        // vmess://base64encodedJSON
        let base64Part = String(uri.dropFirst(8)) // Remove "vmess://"
        
        // Clean up trailing artifacts (some URIs have "vmess" or "vless" appended)
        let cleanBase64 = base64Part
            .replacingOccurrences(of: "vmess", with: "")
            .replacingOccurrences(of: "vless", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Try with padding
            let padded = padBase64(cleanBase64)
            guard let paddedData = Data(base64Encoded: padded, options: .ignoreUnknownCharacters),
                  let json = try? JSONSerialization.jsonObject(with: paddedData) as? [String: Any] else {
                return nil
            }
            return createConfigFromVMessJSON(json)
        }
        
        return createConfigFromVMessJSON(json)
    }
    
    private func createConfigFromVMessJSON(_ json: [String: Any]) -> ServerConfig? {
        guard let address = json["add"] as? String,
              let id = json["id"] as? String else {
            return nil
        }
        
        let port = (json["port"] as? Int) ?? Int(json["port"] as? String ?? "443") ?? 443
        let ps = (json["ps"] as? String) ?? "VMess Server"
        let net = (json["net"] as? String) ?? "tcp"
        let tls = (json["tls"] as? String) ?? ""
        let path = (json["path"] as? String) ?? "/"
        let host = (json["host"] as? String) ?? ""
        let scy = (json["scy"] as? String) ?? "auto"
        
        let networkType: NetworkType = {
            switch net.lowercased() {
            case "ws": return .ws
            case "tcp": return .tcp
            case "grpc": return .grpc
            case "h2", "http": return .http
            default: return .tcp
            }
        }()
        
        return ServerConfig(
            id: UUID(),
            name: ps.isEmpty ? "VMess \(address)" : ps,
            serverAddress: address,
            port: port,
            protocol: .vmess,
            userId: id,
            alterId: 0,
            encryption: scy,
            network: networkType,
            path: path,
            host: host,
            tls: !tls.isEmpty
        )
    }
    
    private func parseVLessURI(_ uri: String) -> ServerConfig? {
        // vless://uuid@host:port?params#name
        guard let url = URL(string: uri.replacingOccurrences(of: "vless://", with: "https://")) else {
            return nil
        }
        
        let components = uri.dropFirst(8) // Remove "vless://"
        guard let atIndex = components.firstIndex(of: "@") else { return nil }
        
        let uuid = String(components[components.startIndex..<atIndex])
        let rest = String(components[components.index(after: atIndex)...])
        
        // Split host:port from params
        var hostPort = rest
        var params: [String: String] = [:]
        var name = "VLESS Server"
        
        if let hashIndex = rest.firstIndex(of: "#") {
            name = String(rest[rest.index(after: hashIndex)...])
                .removingPercentEncoding ?? "VLESS Server"
            hostPort = String(rest[rest.startIndex..<hashIndex])
        }
        
        if let qIndex = hostPort.firstIndex(of: "?") {
            let paramString = String(hostPort[hostPort.index(after: qIndex)...])
            hostPort = String(hostPort[hostPort.startIndex..<qIndex])
            
            for param in paramString.split(separator: "&") {
                let parts = param.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    params[String(parts[0])] = String(parts[1])
                }
            }
        }
        
        // Parse host and port
        let hostPortParts = hostPort.split(separator: ":")
        guard hostPortParts.count >= 1 else { return nil }
        
        let host = String(hostPortParts[0])
        let port = hostPortParts.count > 1 ? Int(hostPortParts[1]) ?? 443 : 443
        
        let networkType: NetworkType = {
            switch params["type"]?.lowercased() ?? "tcp" {
            case "ws": return .ws
            case "grpc": return .grpc
            case "h2", "http": return .http
            default: return .tcp
            }
        }()
        
        return ServerConfig(
            id: UUID(),
            name: name,
            serverAddress: host,
            port: port,
            protocol: .vless,
            userId: uuid,
            alterId: 0,
            encryption: params["encryption"] ?? "none",
            network: networkType,
            path: params["path"] ?? "/",
            host: params["host"] ?? "",
            tls: params["security"] == "tls" || params["security"] == "xtls"
        )
    }
    
    private func parseTrojanURI(_ uri: String) -> ServerConfig? {
        // trojan://password@host:port?params#name
        let components = uri.dropFirst(9) // Remove "trojan://"
        guard let atIndex = components.firstIndex(of: "@") else { return nil }
        
        let password = String(components[components.startIndex..<atIndex])
        let rest = String(components[components.index(after: atIndex)...])
        
        var hostPort = rest
        var name = "Trojan Server"
        
        if let hashIndex = rest.firstIndex(of: "#") {
            name = String(rest[rest.index(after: hashIndex)...])
                .removingPercentEncoding ?? "Trojan Server"
            hostPort = String(rest[rest.startIndex..<hashIndex])
        }
        
        if let qIndex = hostPort.firstIndex(of: "?") {
            hostPort = String(hostPort[hostPort.startIndex..<qIndex])
        }
        
        let hostPortParts = hostPort.split(separator: ":")
        guard hostPortParts.count >= 1 else { return nil }
        
        let host = String(hostPortParts[0])
        let port = hostPortParts.count > 1 ? Int(hostPortParts[1]) ?? 443 : 443
        
        return ServerConfig(
            id: UUID(),
            name: name,
            serverAddress: host,
            port: port,
            protocol: .trojan,
            userId: password,
            alterId: 0,
            encryption: "none",
            network: .tcp,
            path: "/",
            host: "",
            tls: true
        )
    }
    
    private func parseShadowsocksURI(_ uri: String) -> ServerConfig? {
        // ss://base64(method:password)@host:port#name
        // or ss://base64(method:password@host:port)#name
        
        let content = String(uri.dropFirst(5)) // Remove "ss://"
        
        var name = "Shadowsocks Server"
        var mainPart = content
        
        if let hashIndex = content.firstIndex(of: "#") {
            name = String(content[content.index(after: hashIndex)...])
                .removingPercentEncoding ?? "Shadowsocks Server"
            mainPart = String(content[content.startIndex..<hashIndex])
        }
        
        // Try to parse as base64@host:port format
        if let atIndex = mainPart.firstIndex(of: "@") {
            let base64Part = String(mainPart[mainPart.startIndex..<atIndex])
            let hostPart = String(mainPart[mainPart.index(after: atIndex)...])
            
            guard let decoded = decodeBase64(base64Part) else { return nil }
            let methodPassword = decoded.split(separator: ":", maxSplits: 1)
            guard methodPassword.count == 2 else { return nil }
            
            let hostPortParts = hostPart.split(separator: ":")
            guard hostPortParts.count >= 1 else { return nil }
            
            let host = String(hostPortParts[0])
            let port = hostPortParts.count > 1 ? Int(hostPortParts[1]) ?? 443 : 443
            
            return ServerConfig(
                id: UUID(),
                name: name,
                serverAddress: host,
                port: port,
                protocol: .shadowsocks,
                userId: String(methodPassword[1]),
                alterId: 0,
                encryption: String(methodPassword[0]),
                network: .tcp,
                path: "/",
                host: "",
                tls: false
            )
        }
        
        return nil
    }
    
    private func decodeBase64(_ string: String) -> String? {
        let padded = padBase64(string)
        guard let data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private func padBase64(_ string: String) -> String {
        var result = string
        let remainder = result.count % 4
        if remainder > 0 {
            result += String(repeating: "=", count: 4 - remainder)
        }
        return result
    }
}
