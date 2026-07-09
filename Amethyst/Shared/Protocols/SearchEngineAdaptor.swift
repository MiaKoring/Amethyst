//
//  SearchEngine.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 02.12.24.
//

import Foundation
@MainActor
protocol SearchEngineAdaptor {
    static var name: String { get }
    static func quickResults(query: String) async -> [String]
}

extension SearchEngineAdaptor {
    static func decodeArray(jsonData: Data, useIndex index: Int = 1) -> [String] {
        guard
            let array = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any]
        else {
            return []
        }
        
        return array[index, default: []] as? [String] ?? []
    }
}
