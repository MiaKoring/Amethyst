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
class CDHistoryController {
    public static nonisolated let shared = CDHistoryController(name: "History")
    let container: NSPersistentContainer
    private static nonisolated let logger = Logger(subsystem: AmethystApp.subSystem, category: "CDHistoryController")
    
    private nonisolated init(name: String) {
        container = NSPersistentContainer(name: name)
        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.error("Error initializing CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAll(sortDescriptors: [NSSortDescriptor] = []) -> [HistoryDay] {
        let request = HistoryDay.createFetchRequest()
        request.includesSubentities = false
        request.sortDescriptors = sortDescriptors
        do {
            return try container.viewContext.fetch(request)
        } catch {
            Self.logger.error("Error while fetching all HistoryDays: \(error.localizedDescription)")
        }
        return []
    }
    
    func delete(_ item: HistoryItem) {
        container.viewContext.delete(item)
        save()
    }
    
    func clearEntity() {
        container.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryDay")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs

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
                Self.logger.error("An error occured while emptying HistoryDay: \(error.localizedDescription)")
            }
        }
    }
    
    func printKnownEntities() {
        Self.logger.info("Known Entities: \(self.container.managedObjectModel.entities.compactMap(\.name))")
    }
    
    func insertHistoryDay(_ day: HistoryDay) {
        container.viewContext.insert(day)
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
    
    func dayFetchCount(_ predicate: Predicate<HistoryDay>) -> Int {
        let request = HistoryDay.createFetchRequest()
        request.predicate = NSPredicate(predicate)
        do {
            return try container.viewContext.count(for: request)
        } catch {
            Self.logger.error("Error while fetching count with Predicate")
        }
        return 0
    }
    
    func itemFetchCount(_ predicate: Predicate<HistoryItem>) -> Int {
        let request = HistoryItem.createFetchRequest()
        request.predicate = NSPredicate(predicate)
        do {
            return try container.viewContext.count(for: request)
        } catch {
            Self.logger.error("Error while fetching count with Predicate")
        }
        return 0
    }
    
    func fetchOrCreateHistoryDay() -> HistoryDay {
        let rangeStart = Calendar.current.startOfDay(for: Date.now).timeIntervalSinceReferenceDate

        let request = HistoryDay.createFetchRequest()
        request.predicate = NSPredicate(
            #Predicate<HistoryDay>{
            $0.dayTime == rangeStart
        })
        request.fetchLimit = 1
        
        do {
            if let day = try container.viewContext.fetch(request).first { return day }
        } catch {
            Self.logger.log("Failed to create HistoryDay: \(error.localizedDescription)")
        }
        return createAndSaveHistoryDay(rangeStart: rangeStart)
        
        func createAndSaveHistoryDay(rangeStart: Double) -> HistoryDay {
            let day = HistoryDay()
            day.dayTime = rangeStart
            insertHistoryDay(day)
            return day
        }
    }
    
}

extension CDHistoryController {
    static func fetchAll(sortDescriptors: [NSSortDescriptor] = []) -> [HistoryDay] {
        CDHistoryController.shared.fetchAll(sortDescriptors: sortDescriptors)
    }
    
    static func save() {
        CDHistoryController.shared.save()
    }
    
    static func insertHistoryDay(_ day: HistoryDay) {
        CDHistoryController.shared.insertHistoryDay(day)
    }
    
    static func clear() {
        CDHistoryController.shared.clearEntity()
    }
    
    static func dayFetchCount(_ predicate: Predicate<HistoryDay>) -> Int {
        CDHistoryController.shared.dayFetchCount(predicate)
    }
    
    static func itemFetchCount(_ predicate: Predicate<HistoryItem>) -> Int {
        CDHistoryController.shared.itemFetchCount(predicate)
    }
    
    static func delete(_ item: HistoryItem) {
        CDHistoryController.shared.delete(item)
    }
    
    static var currentHistoryDay: HistoryDay {
        CDHistoryController.shared.fetchOrCreateHistoryDay()
    }
    
}
