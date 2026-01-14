//
//  ConfigManager.swift
//  V2RayUSA
//
//  Manages server configuration persistence
//

import Foundation
import Combine

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "savedServerConfigs"
    
    private init() {}
    
    func loadDefaultConfig() -> ServerConfig {
        // Load saved configs
        if let configs = loadSavedConfigs(), let first = configs.first {
            return first
        }
        
        // Return template config
        return ServerConfig()
    }
    
    func loadSavedConfigs() -> [ServerConfig]? {
        guard let data = userDefaults.data(forKey: configKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode([ServerConfig].self, from: data)
    }
    
    func saveConfig(_ config: ServerConfig) {
        var configs = loadSavedConfigs() ?? []
        
        // Update existing or append new
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        
        if let data = try? JSONEncoder().encode(configs) {
            userDefaults.set(data, forKey: configKey)
        }
    }
    
    func deleteConfig(_ id: UUID) {
        var configs = loadSavedConfigs() ?? []
        configs.removeAll { $0.id == id }
        
        if let data = try? JSONEncoder().encode(configs) {
            userDefaults.set(data, forKey: configKey)
        }
    }
    
    func exportConfig(_ config: ServerConfig, to url: URL) throws {
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)
    }
    
    func importConfig(from url: URL) throws -> ServerConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ServerConfig.self, from: data)
    }
}
