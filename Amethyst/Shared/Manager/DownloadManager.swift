//
//  Download.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 10.12.24.
//
import SwiftUI
import CoreData
import OSLog
import WebKit

@MainActor
@Observable
class DownloadManager: NSObject {
    @ObservationIgnored
    private var observations = [WKDownload: NSKeyValueObservation]()
    
    public static var downloadsExtension = "amthDownload"
    var activeDownloads: [WKDownload: DownloadInfo] = [:]
    
    private static var logger = Logger(subsystem: AmethystApp.subSystem, category: "DownloadManager")
        
    override init() {
        super.init()
    }
    
    func startTracking(download: WKDownload, withName name: String?) {
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        // The final filename might be provided by the download object itself later.
        let filename = name ?? download.originalRequest?.url?.lastPathComponent ?? "Download"
        let targetURL = downloadsDirectory.appendingPathComponent(filename)
        
        let downloadInfo = DownloadInfo(download: download, targetURL: targetURL)
        
        activeDownloads[download] = downloadInfo
        Self.logger.info("Started tracking new WKDownload for \(filename)")
        
        observations[download] = download.progress.observe(\.fractionCompleted, options: [.new]) { [weak self, weak download] observedProgress, change in
            guard let download, let newValue = change.newValue else { return }
            
            Task { @MainActor in
                self?.updateProgress(for: download, progress: newValue, downloadedBytes: download.progress.completedUnitCount, totalBytes: download.progress.totalUnitCount)
            }
        }
    }
    
    func updateProgress(for download: WKDownload, progress: Double, downloadedBytes: Int64, totalBytes: Int64) {
        if let downloadInfo = activeDownloads[download] {
            downloadInfo.progress = progress
            downloadInfo.downloadedBytes = downloadedBytes
            downloadInfo.totalBytes = totalBytes
        }
    }
    
    func finishDownload(for download: WKDownload) {
        defer { observations[download] = nil }
        guard let downloadInfo = activeDownloads.removeValue(forKey: download) else {
            Self.logger.warning("Finished download for an untracked WKDownload.")
            return
        }
        
        if let destinationURL = downloadInfo.destinationURL {
            saveBookmark(targetURL: destinationURL)
            Self.logger.info("Successfully moved downloaded file to \(destinationURL.path)")
        }
    }
    
    func failDownload(for download: WKDownload, error: Error, resumeData: Data?) {
        defer { observations[download] = nil }
        
        activeDownloads[download]?.didFail = true
        Self.logger.error("Download failed for \(download.debugDescription) with error: \(error.localizedDescription)")
        // TODO: Add resume logic
    }
    
    func determineUniqueTargetURL(for originalURL: URL, download: WKDownload) -> URL {
        var targetURL = originalURL
        let fileManager = FileManager.default
        var suffix = 0
        
        let fileExtension = originalURL.pathExtension
        let fileNameWithoutExtension = {
            let initialURL = originalURL.deletingPathExtension().lastPathComponent
            guard !initialURL.isEmpty else {
                return "AmethystDownload"
            }
            return initialURL
        }()
        
        let directory = originalURL.deletingLastPathComponent()
        
        while fileManager.fileExists(atPath: targetURL.path) {
            suffix += 1
            let newFileName = "\(fileNameWithoutExtension) (\(suffix))"
            targetURL = directory
                .appendingPathComponent(newFileName)
                .appendingPathExtension(fileExtension)
        }
        
        activeDownloads[download]?.destinationURL = targetURL
        
        return targetURL.appendingPathExtension(Self.downloadsExtension)
    }
    
    func cancelDownload(_ download: WKDownload?) {
        guard let download else {
            Self.logger.error("failed to cancel download, recieved nil value")
            return
        }
        defer { observations[download] = nil }
        
        if let info = activeDownloads[download],
           let destination = info.destinationURL {
            download.cancel()
            info.isCanceled = true
            info.progress = -1
            do {
                try FileManager.default.removeItem(at: destination.appendingPathExtension(DownloadManager.downloadsExtension))
            } catch {
                Self.logger.error("Failed to remove dangling temp download file with error: \(error.localizedDescription)")
            }
        } else {
            Self.logger.error("Failed to remove dangling temp download file with reason: couldn't find destination)")
        }
    }
    
    private func saveBookmark(targetURL: URL) {
        do {
            do {
                try FileManager.default.moveItem(at: targetURL.appendingPathExtension(Self.downloadsExtension), to: targetURL)
            } catch {
                Self.logger.error("failed to set quarantine value for: \(targetURL.absoluteString)\nwith error: \(error.localizedDescription)")
            }
            
            let bookmark = try targetURL.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: [.nameKey, .contentTypeKey, .creationDateKey],
                relativeTo: nil
            )
            let downloaded = DownloadedItem()
            downloaded.createdAt =  Date.now.timeIntervalSinceReferenceDate
            downloaded.bookmark = bookmark
            CDDownloadsController.insert(downloaded)
        } catch {
            Self.logger.error("failed to create Bookmark with Error: \(error.localizedDescription)")
        }
    }
}
