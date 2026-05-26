//
//  CDTabController.swift
//  Amethyst Project
//
//  Created by Mia Koring on 17.04.25.
//

import Foundation
import CoreData
import OSLog

@MainActor
class CDTabController {
    public static nonisolated let shared = CDTabController(name: "Tabs")
    nonisolated let container: NSPersistentContainer
    private static nonisolated let logger = Logger(subsystem: AmethystApp.subSystem, category: "CDTabController")
    
    private nonisolated init(name: String) {
        container = NSPersistentContainer(name: name)
        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.error("Error initializing CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAll() -> [SavedTab] {
        let request = SavedTab.createFetchRequest()
        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching all SavedTabs: \(error.localizedDescription)")
        }
        return []
    }
    
    //only in background, doesn't need view updates
    func clearEntity() {
        container.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedTab")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [context]
                    )
                }
            } catch {
                Self.logger.error("An error occured while emptying SavedTabs: \(error.localizedDescription)")
            }
        }
    }
    
    func printKnownEntities() {
        Self.logger.info("Known Entities: \(self.container.managedObjectModel.entities.compactMap(\.name))")
    }
    
    func insertSavedTab(_ tab: SavedTab) {
        container.viewContext.insert(tab)
        save()
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                Self.logger.error("Error saving CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchCount(_ predicate: NSPredicate) -> Int {
        let request = SavedTab.createFetchRequest()
        request.predicate = predicate
        do {
            return try container.viewContext.count(for: request)
        } catch {
            Self.logger.error("Error while fetching count with Predicate: \(error.localizedDescription)")
        }
        return 0
    }
    
    func fetchAllFor(windowID: String) -> [SavedTab] {
        let request = SavedTab.createFetchRequest()
        request.predicate = NSPredicate(format: "windowID == %@", windowID)
        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching count with Predicate: \(error.localizedDescription)")
        }
        return []
    }
    
    func deleteFor(windowID: String) {
        container.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedTab")
            fetchRequest.predicate = NSPredicate(format: "windowID == %@", windowID)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [context]
                    )
                }
            } catch {
                Self.logger.error("An error occured while emptying SavedTabs for windowID \(windowID): \(error.localizedDescription)")
            }
        }
        
    }
    
}

extension CDTabController {
    static func fetchAll() -> [SavedTab] {
        CDTabController.shared.fetchAll()
    }
    
    static func fetchAllFor(windowID: String) -> [SavedTab] {
        CDTabController.shared.fetchAllFor(windowID: windowID)
    }
    
    static func save() {
        CDTabController.shared.save()
    }
    
    static func insertSavedTab(_ tab: SavedTab) {
        CDTabController.shared.insertSavedTab(tab)
    }
    
    static func clear() {
        CDTabController.shared.clearEntity()
    }
    
    static func fetchCount(_ predicate: NSPredicate) -> Int {
        CDTabController.shared.fetchCount(predicate)
    }
    
    static func deleteFor(windowID: String) {
        CDTabController.shared.deleteFor(windowID: windowID)
    }
    
}
