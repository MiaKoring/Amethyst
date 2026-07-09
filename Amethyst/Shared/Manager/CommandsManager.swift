import SwiftUI
import TipKit

@Observable
final class CommandsManager: ShortcutFeatureManager {
    static let shared = CommandsManager()
    
    private init() {}
    
    private var commands = [String: String]()
    
    var registered: [String: String] {
        commands
    }
    
    func resolve(_ query: String) -> String? {
        guard query.hasPrefix(":") else { return nil }
        
        let key = "\(query.dropFirst())"
        
        guard
            let destination = commands[key]
        else { return nil }
        
        return "\(destination)"
    }
    
    func remove(key: String) {
        guard
            let commandsData = UDKey.commands.data,
            var decoded = try? JSONDecoder().decode([String: String].self, from: commandsData)
        else {
            commands = [:]
            UDKey.commands.data = nil
            return
        }
        
        decoded[key] = nil
        commands = decoded
        
        UDKey.commands.data = try? JSONEncoder().encode(decoded)
    }
    
    func set(_ destination: String, for key: String) {
        guard
            let commandsData = UDKey.commands.data,
            var decoded = try? JSONDecoder().decode([String: String].self, from: commandsData)
        else {
            commands = [key: destination]
            UDKey.commands.data = try? JSONEncoder().encode(commands)
            return
        }
        
        decoded[key] = destination
        commands = decoded
        
        UDKey.commands.data = try? JSONEncoder().encode(decoded)
    }
    
    func fetch() {
        guard
            let commandsData = UDKey.commands.data,
            let decoded = try? JSONDecoder().decode([String: String].self, from: commandsData)
        else { return }
        commands = decoded
    }
    
    var tip: any Tip = CommandsTip()
}
