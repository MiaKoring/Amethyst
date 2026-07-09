//
//  SEDuckDuckGo.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 02.12.24.
//

import Foundation

struct SEDuckDuckGo: SearchEngineAdaptor {
    static let name: String = "DuckDuckGo"
    
    static func quickResults(query: String) async -> [String] {
        guard let url = URL(string: "https://duckduckgo.com/ac/?q=\(query.replacingOccurrences(of: " ", with: "+"))&type=json") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let response = try? await URLSession.shared.data(for: request) else { return [] }
        guard  let data = try? JSONDecoder().decode([DDGacResult].self, from: response.0) else { return [] }
        return data.compactMap({$0.phrase})
    }
}


struct DDGacResult: Codable {
    let phrase: String
}
