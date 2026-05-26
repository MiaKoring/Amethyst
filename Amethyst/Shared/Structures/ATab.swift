//
//  Tab.swift
//  Browser
//
//  Created by Mia Koring on 27.11.24.
//

import WebKit

struct ATab: Hashable, Equatable, Identifiable {
    var id: UUID
    var webViewModel: WebViewModel
    
    init(id: UUID, webViewModel: WebViewModel) {
        self.id = id
        self.webViewModel = webViewModel
    }
    
    static func ==(lhs: ATab, rhs: ATab) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
