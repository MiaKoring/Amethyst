//
//  WKDownloadDelegate.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//
import WebKit
import Foundation

extension WebViewModel: WKDownloadDelegate {
    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        print("Download started from navigationAction: \(download.originalRequest?.url?.lastPathComponent ?? "unknown")")
        download.delegate = self // Set the delegate for this specific download's progress
        appViewModel.downloadManager?.startTracking(download: download, withName: navigationAction.request.url?.lastPathComponent)
        animateDownloadStart()
    }
    
    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        print("Download started from navigationResponse: \(download.originalRequest?.url?.lastPathComponent ?? "unknown")")
        download.delegate = self
        appViewModel.downloadManager?.startTracking(download: download, withName: navigationResponse.response.suggestedFilename)
        
        animateDownloadStart()
    }
    
    private func animateDownloadStart() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.downloadCreatedTimer?.invalidate()
            self.downloadCreatedTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.downloadCreatedTimer = nil
                }
            }
        }
    }
    
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let url = downloadsURL.appendingPathComponent(suggestedFilename)
            return appViewModel.downloadManager?.determineUniqueTargetURL(for: url, download: download)
        }
        print("no destination found")
        return nil
    }
    
    func download(_ download: WKDownload, didFinishDownloadingTo location: URL) {
        appViewModel.downloadManager?.finishDownload(for: download)
    }
    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        appViewModel.downloadManager?.failDownload(for: download, error: error, resumeData: resumeData)
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        appViewModel.downloadManager?.finishDownload(for: download)
    }
}
