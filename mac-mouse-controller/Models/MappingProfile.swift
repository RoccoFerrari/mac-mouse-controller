//
//  MappingProfile.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
internal import Combine

struct MappingRule: Identifiable, Codable {
    var id = UUID()
    
    // trigger (Input)
    var mouseButton: MouseButton
    var requiredModifiers: ModifierSet // Es. if press key while keep pressed CMD
    
    // action (Output)
    var action: ActionType
    
    var isEnabled: Bool = true
}

/// Class containing a set of rules for a user
class UserProfile: ObservableObject, Codable {
    @Published var rules: [MappingRule] = [] {
        didSet {
            saveToDisk()
        }
    }
    
    // Key to save data
    private let storageKey = "MouseController_Rules_V1"
    
    // Method neede to support @Published with Codable
    enum CodingKeys: CodingKey {
        case rules
    }
    
    init() {
        loadFromDisk()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rules = try container.decode([MappingRule].self, forKey: .rules)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rules, forKey: .rules)
    }
    
    // MARK: Persistence Logic
    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("Configurationsaved: \(rules.count) rules")
        } catch {
            print("Failed to save rules: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("No saved configurations")
            return
        }
        
        do {
            let encoder = JSONDecoder()
            let savedRules = try encoder.decode(UserProfile.self, from: data)
            self.rules = savedRules.rules
            print("Configurations loaded: \(rules.count) rules")
        } catch {
            print("Failed to load rules: \(error)")
        }
    }
}
