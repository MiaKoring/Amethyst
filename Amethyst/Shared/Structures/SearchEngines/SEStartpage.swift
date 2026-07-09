//
//  SEStartpage.swift
//  Amethyst Project
//
//  Created by Mia Koring on 01.06.25.
//


import Foundation
struct SEStartpage: SearchEngineAdaptor {
    static let name: String = "Startpage"
    
    static func quickResults(query: String) async -> [String] {
        guard let url = URL(string: "https://www.startpage.com/osuggestions?q=\(query.replacingOccurrences(of: " ", with: "+"))&type=json") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let response = try? await URLSession.shared.data(for: request) else { return [] }
        return SEStartpage.decodeArray(jsonData: response.0, useIndex: 1)
    }
}
