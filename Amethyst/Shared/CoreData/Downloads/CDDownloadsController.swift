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
final class CDDownloadsController: ObservableObject {
    public static nonisolated let shared = CDDownloadsController(name: "Downloads")
    private static nonisolated let logger = Logger(subsystem: AmethystApp.subSystem, category: "CDDownloadsController")
    let container: NSPersistentContainer
    
    @Published var latestFour = [DownloadedItem]()
    
    private nonisolated init(name: String) {
        container = NSPersistentContainer(name: name)
        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.error("Error initializing CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAll(sortDescriptors: [NSSortDescriptor] = []) -> [DownloadedItem] {
        let request = DownloadedItem.createFetchRequest()
        request.sortDescriptors = sortDescriptors
        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching all SavedTabs: \(error.localizedDescription)")
        }
        return []
    }
    
    func delete(_ item: DownloadedItem) {
        container.viewContext.delete(item)
        save()
    }
    
    func fetchLatestFour() -> [DownloadedItem] {
        let request = DownloadedItem.createFetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                SortDescriptor(\DownloadedItem.createdAt, order: .reverse)
            )
        ]
        request.fetchLimit = 4
        
        do {
            let latest = try container.viewContext.fetch(request)
            return latest
        } catch {
            Self.logger.error("Error while fetching latest DownloadedItems: \(error.localizedDescription)")
        }
        return []
    }
    
    func clearEntity() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DownloadedItem")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try container.viewContext.execute(batchDeleteRequest)
            save()
        } catch {
            Self.logger.error("An error occured while emptying SavedTabs: \(error.localizedDescription)")
        }
    }
    
    func printKnownEntities() {
        Self.logger.info("Known Entities: \(self.container.managedObjectModel.entities.compactMap(\.name))")
    }
    
    func insertDownloadedItem(_ item: DownloadedItem) {
        container.viewContext.insert(item)
        save()
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
                latestFour = fetchLatestFour()
            } catch {
                Self.logger.error("Error saving CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchCount(_ predicate: Predicate<DownloadedItem>) -> Int {
        let request = DownloadedItem.createFetchRequest()
        request.predicate = NSPredicate(predicate)
        do {
            return try container.viewContext.count(for: request)
        } catch {
            Self.logger.error("Error while fetching count with Predicate: \(error.localizedDescription)")
        }
        return 0
    }
    
}

extension CDDownloadsController {
    static func fetchAll() -> [DownloadedItem] {
        CDDownloadsController.shared.fetchAll()
    }
    
    static func save() {
        CDDownloadsController.shared.save()
    }
    
    static func insert(_ item: DownloadedItem) {
        CDDownloadsController.shared.insertDownloadedItem(item)
    }
    
    static func clear() {
        CDDownloadsController.shared.clearEntity()
    }
    
    static func fetchCount(_ predicate: Predicate<DownloadedItem>) -> Int {
        CDDownloadsController.shared.fetchCount(predicate)
    }
    
    static func delete(_ item: DownloadedItem) {
        CDDownloadsController.shared.delete(item)
    }
    
}
