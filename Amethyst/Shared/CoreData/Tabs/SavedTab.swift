//
//  SavedTab.swift
//  Amethyst Project
//
//  Created by Mia Koring on 17.04.25.
//
import Foundation
import CoreData

@MainActor
@objc(SavedTab)
public class SavedTab: NSManagedObject {
    convenience init() {
        self.init(context: CDTabController.shared.container.viewContext)
    }
}
