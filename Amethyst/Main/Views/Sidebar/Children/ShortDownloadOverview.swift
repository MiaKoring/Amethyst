//
//  ShortDownloadOverviewModl.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 09.02.25.
//
import SwiftUI
import SwiftData

struct ShortDownloadOverview: View {
    @Environment(AppViewModel.self) var appViewModel
    @State var displayedItems: [DownloadItem] = []
    @ObservedObject var downloadsController = CDDownloadsController.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            if !appViewModel.useMacOS26Design {
                Divider()
            }
            if !displayedItems.isEmpty {
                ForEach(displayedItems, id: \.self) { item in
                    ShortDownloadOverviewItem(item: item, update: updateDisplayedItems)
                        .padding(.horizontal, 5)
                }
            }
        }
        .onAppear(perform: updateDisplayedItems)
    }
    
    func updateDisplayedItems() {
        downloadsController.latestFour = downloadsController.fetchLatestFour()
        let active = appViewModel.downloadManager?.activeDownloads.prefix(4).map { item in
            DownloadItem(name: item.value.targetURL.lastPathComponent, dateCreated: Date.now.timeIntervalSinceReferenceDate, url: nil, icon: Image(nsImage: NSWorkspace.shared.icon(for: .init(item.value.targetURL.pathExtension) ?? .data)), info: item.value)
        }
        var newest: [DownloadItem] = []
        
        let newestDownloadedItems = downloadsController.latestFour.filter({$0.createdAt > Date.now.timeIntervalSinceReferenceDate - 3600 * 24 * 7}).prefix(4)
        
        for item in newestDownloadedItems {
            var bookmarkDataIsStale: Bool = false
            guard let bookmark = item.bookmark, let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &bookmarkDataIsStale) else {
                continue
            }
            
            guard let activeCount = active?.count, newest.count + activeCount < 4 else { continue }
            if bookmarkDataIsStale, let bookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: [.nameKey, .contentTypeKey, .creationDateKey],
                relativeTo: nil
            ) {
                item.bookmark = bookmarkData
            }
            
            guard !FileManager.default.isInTrash(url), let ressourceValues = try? url.resourceValues(forKeys: [.nameKey, .typeIdentifierKey]), let name = ressourceValues.name, let typeIdentifier = ressourceValues.typeIdentifier else {
                downloadsController.delete(item)
                continue
            }
            newest.append(DownloadItem(name: name, dateCreated: item.createdAt, url: url, icon: Image(nsImage: NSWorkspace.shared.icon(for: .init(typeIdentifier) ?? .data)), info: nil))
        }
        newest.sort(by: {
            if $0.dateCreated == $1.dateCreated {
                return $0.name > $1.name
            } else {
                return $0.dateCreated > $1.dateCreated
            }
        })
        newest.insert(contentsOf: active ?? [], at: 0)
        displayedItems = newest
    }
    
}

extension FileManager {
    public func isInTrash(_ file: URL) -> Bool {
        var relationship: URLRelationship = .other
        try? getRelationship(
            &relationship,
            of: .trashDirectory,
            in: .allDomainsMask,
            toItemAt: file
        )
        return relationship == .contains
    }
}
