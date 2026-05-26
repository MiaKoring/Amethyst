import SwiftUI
import TipKit

@Observable
final class BangManager: ShortcutFeatureManager {
    static let shared = BangManager()
    
    private init() {}
    
    private var bangs = [String: String]()
    
    var registered: [String: String] {
        bangs
    }
    
    func resolve(_ query: String) -> String? {
        guard query.hasPrefix("!") else { return nil }
        
        let parts = query
            .dropFirst()
            .split(separator: " ", maxSplits: 1)
            .map { String($0) }
        
        guard
            parts.count == 2,
            let destination = bangs[parts[0]]
        else { return nil }
        
        return "\(destination)\(parts[1].addingPercentEncoding(withAllowedCharacters: []) ?? parts[1])"
    }
    
    func remove(key: String) {
        guard
            let bangData = UDKey.bangs.data,
            var decoded = try? JSONDecoder().decode([String: String].self, from: bangData)
        else {
            bangs = [:]
            UDKey.bangs.data = nil
            return
        }
        
        decoded[key] = nil
        bangs = decoded
        
        UDKey.bangs.data = try? JSONEncoder().encode(decoded)
    }
    
    func set(_ destination: String, for key: String) {
        guard
            let bangData = UDKey.bangs.data,
            var decoded = try? JSONDecoder().decode([String: String].self, from: bangData)
        else {
            bangs = [key: destination]
            UDKey.bangs.data = try? JSONEncoder().encode(bangs)
            return
        }
        
        decoded[key] = destination
        bangs = decoded
        
        UDKey.bangs.data = try? JSONEncoder().encode(decoded)
    }
    
    func fetch() {
        guard
            let bangData = UDKey.bangs.data,
            let decoded = try? JSONDecoder().decode([String: String].self, from: bangData)
        else { return }
        bangs = decoded
    }
    
    var tip: any Tip = BangTip()
}
@MainActor
protocol ShortcutFeatureManager: Observable {
    func fetch() -> Void
    func set(_ destination: String, for key: String) -> Void
    func remove(key: String)
    func resolve(_ query: String) -> String?
    var registered: [String: String] { get }
    var tip: any Tip { get }
}
