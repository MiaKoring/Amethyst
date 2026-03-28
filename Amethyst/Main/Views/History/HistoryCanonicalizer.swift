//
//  HistoryCanonicalizer.swift
//  Amethyst Browser
//
//  Created by Codex on 28.03.26.
//

import Foundation

enum HistoryCanonicalizer {
    static func canonicalURLString(for url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        components.fragment = nil
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()

        if let port = components.port, let scheme = components.scheme {
            let isDefaultPort = (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
            if isDefaultPort {
                components.port = nil
            }
        }

        if components.path.isEmpty {
            components.path = "/"
        }

        return components.string ?? url.absoluteString
    }
}
