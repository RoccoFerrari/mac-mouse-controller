//
//  MappingProfile.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
internal import Combine

/// **Single Mapping Rule**
///
/// Represents a specific configuration that maps a physical input to a software action.
/// - `mouseButton`: The physical button pressed.
/// - `requiredModifiers`: Keyboard modifiers (Cmd, Shift, etc.) that must be held down.
/// - `action`: The resulting command or macro to execute.
struct MappingRule: Identifiable, Codable {
    var id = UUID()
    
    // trigger (Input)
    var mouseButton: MouseButton
    var requiredModifiers: ModifierSet // Es. if press key while keep pressed CMD
    
    // action (Output)
    var action: ActionType
    
    /// Determines if this specific rule is currently active.
    var isEnabled: Bool = true
}

/// **User Configuration Manager**
///
/// This class acts as the data model for the application's settings.
/// It combines reactive UI updates (`ObservableObject`) with data persistence (`Codable`).
///
/// - Responsibilities:
///   1. Store the list of mapping rules.
///   2. Store global settings (scrolling direction, smoothing).
///   3. Handle serialization (JSON) and storage (UserDefaults).
class UserProfile: ObservableObject, Codable {
    
    /// The collection of all button mappings defined by the user.
    /// - Note: The `didSet` observer ensures that any change to this array immediately triggers a save to disk.
    @Published var rules: [MappingRule] = [] {
        didSet {
            saveToDisk()
        }
    }
    
    /// Global setting to reverse scroll direction (Natural Scrolling override).
    @Published var invertScrolling: Bool = false {
        didSet {saveToDisk() }
    }
    
    /// Global setting to enable algorithmic smoothing of scroll events.
    @Published var smoothScrolling: Bool = false {
        didSet {saveToDisk() }
    }
    
    // Key to save data
    /// The unique identifier used to store this profile in `UserDefaults`.
    private let storageKey = "MouseController_Rules_V1"
    
    // Method neede to support @Published with Codable
    /// keys used for encoding/decoding.
    enum CodingKeys: CodingKey {
        case rules
        case invertScrolling
        case smoothScrolling
    }
    
    /// Default initializer: loads data from persistence immediately.
    init() {
        loadFromDisk()
    }
    
    /// **Custom Decoding**
    ///
    /// Required because `@Published` properties wrappers do not automatically conform to `Decodable`.
    /// We must manually decode the values and assign them to the properties.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rules = try container.decode([MappingRule].self, forKey: .rules)
        invertScrolling = try container.decodeIfPresent(Bool.self, forKey: .invertScrolling) ?? false
        smoothScrolling = try container.decodeIfPresent(Bool.self, forKey: .smoothScrolling) ?? false
    }
    
    /// **Custom Encoding**
    ///
    /// Required to unwrap the `@Published` values and encode the raw data into JSON.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rules, forKey: .rules)
        try container.encode(invertScrolling, forKey: .invertScrolling)
        try container.encode(smoothScrolling, forKey: .smoothScrolling)
    }
    
    // MARK: Persistence Logic
    
    /// Serializes the current state of the object to JSON and writes it to `UserDefaults`.
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
    
    /// Reads binary data from `UserDefaults`, decodes it from JSON, and restores the state.
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
