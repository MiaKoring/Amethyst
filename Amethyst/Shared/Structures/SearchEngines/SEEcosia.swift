//
//  SEEcosia.swift
//  Amethyst Project
//
//  Created by Mia Koring on 01.06.25.
//

import Foundation
struct SEEcosia: SearchEngineAdaptor {
    static let name: String = "Ecosia"
    
    static func quickResults(query: String) async -> [String] {
        guard let url = URL(string: "https://ac.ecosia.org/?limit=8&q=\(query.replacingOccurrences(of: " ", with: "+"))&type=json") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let response = try? await URLSession.shared.data(for: request) else { return []}
            
        return (try? JSONDecoder().decode(EcosiaAcResult.self, from: response.0).suggestions) ?? []
    }
}
struct EcosiaAcResult: Codable {
    let suggestions: [String]
}
