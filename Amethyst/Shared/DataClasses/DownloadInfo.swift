

import Foundation
import WebKit
import Combine

@MainActor
@Observable
class DownloadInfo: @MainActor Identifiable, @MainActor Hashable {
    // Use the download object for identity and hashing
    var id: WKDownload { download }

    let targetURL: URL
    let originalURL: URL?
    
    var progress: Double = 0.0
    var totalBytes: Int64 = 0
    var downloadedBytes: Int64 = 0
    
    var destinationURL: URL?
    var didFail: Bool = false
    var isCanceled: Bool = false
    var isFinished: Bool = false
    
    let download: WKDownload
    
    // This will hold our Key-Value Observation
    private var progressObservation: NSKeyValueObservation?

    init(download: WKDownload, targetURL: URL) {
        self.download = download
        self.targetURL = targetURL
        self.originalURL = download.originalRequest?.url
        
        // Start observing the progress object of the WKDownload
        self.observeProgress()
    }
    
    private func observeProgress() {
        // WKDownload.progress is a Progress object that is Key-Value Observable.
        // We observe its `fractionCompleted` property.
        progressObservation = download.progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
            // This closure is called whenever the progress changes.
            // We must update our properties on the main thread for UI safety.
            Task { @MainActor in
                self?.updateProgress(progress)
            }
        }
    }
    
    private func updateProgress(_ progress: Progress) {
        self.progress = progress.fractionCompleted
        self.totalBytes = progress.totalUnitCount
        self.downloadedBytes = progress.completedUnitCount
    }
    
    // We need to implement Hashable and Equatable to use this in collections
    static func == (lhs: DownloadInfo, rhs: DownloadInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Call this to stop the download
    func cancel() {
        download.cancel { _ in
            // The download data can be used to resume later if needed
        }
    }
}
