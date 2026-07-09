//
//  NavigationDelegate.swift
//  Amethyst Browser
//
//  Created by Mia Koring on 04.12.24.
//
import SwiftData
@preconcurrency import WebKit
import OSLog

extension WebViewModel: WKNavigationDelegate {
    static let logger = Logger(subsystem: AmethystApp.subSystem, category: "WebViewModel")
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        Self.logger.debug(
            "Decide Policy for Action: \(navigationAction.request.url?.absoluteString ?? "N/A")"
        )
        
        guard let url = navigationAction.request.url else {
            return .allow
        }
        
        let externalSchemes = ["mailto", "tel", "sms", "facetime"]

        if let scheme = url.scheme, externalSchemes.contains(scheme) {
            NSWorkspace.shared.open(url)
            return .cancel
        }
        
        // Save the referer, so downloads that expect a referer still work.
        // This only updates if a Referer header is present.
        if let referer = navigationAction.request.allHTTPHeaderFields?["Referer"] {
            self.referer = referer
        }
        
        // Manage custom cache behavior based on navigation type.
        if contentViewModel.isLoaded {
            switch navigationAction.navigationType {
            case .reload, .backForward, .formResubmitted, .formSubmitted:
                cache = nil
            case .linkActivated, .other:
                cache = true
            @unknown default:
                cache = nil
            }
        }
        
        if navigationAction.shouldPerformDownload {
            return .download
        }
        
        if navigationAction.targetFrame == nil {
            return .cancel
        }
        
        return .allow
    }
    
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
    ) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
              let url = response.url else {
            decisionHandler(.allow)
            return
        }
        
        // Avoid re-processing a URL we've already decided to download in this sequence.
        if blockDownloadCheckforURL == url {
            // This can happen for subsequent chunks or redirects.
            // Cancelling prevents WebKit from trying to render the file.
            decisionHandler(.cancel)
            return
        }
        
        var isDownload = false
        // 1. Check for 'Content-Disposition: attachment' header. This is the strongest indicator.
        let dispositionKey = response.allHeaderFields.keys.first {
            ($0 as? String)?.lowercased() == "content-disposition"
        }
        if let key = dispositionKey,
           let disposition = response.allHeaderFields[key] as? String,
           disposition.lowercased().contains("attachment")
        {
            isDownload = true
            Self.logger.debug(
                "Download detected by Content-Disposition for \(url.absoluteString)"
            )
        }
        
        // 2. Check if WebKit can't render the MIME type.
        if !isDownload && !navigationResponse.canShowMIMEType {
            isDownload = true
            Self.logger.debug(
                "Download detected: WebKit cannot show MIMEType '\(response.mimeType ?? "N/A")'"
            )
        }
        
        // 3. Check against a list of known "download-only" MIME types as a fallback.
        if !isDownload, let mimeType = response.mimeType?.lowercased() {
            let knownDownloadMimeTypes = [
                "application/octet-stream", // Generic binary
                "binary/octet-stream",
                "application/zip",
                "application/x-zip-compressed",
                "application/x-rar-compressed",
                "application/gzip",
                "application/x-tar",
                "application/pdf", // Add other specific types as needed, e.g., "application/pdf" if you always want to download PDFs.
            ]
            if knownDownloadMimeTypes.contains(mimeType) {
                isDownload = true
                Self.logger.debug(
                    "Download detected by known MIMEType '\(mimeType)'"
                )
            }
        }
        
        if isDownload {
            decisionHandler(.download)
        } else {
            // The content is not a download, allow WebKit to render it.
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Self.logger.info(
            "DidFinish Navigation for: \(webView.url?.absoluteString ?? "N/A")"
        )
        error = nil
        blockDownloadCheckforURL = nil // Reset download check state on success.
        appendHistory()
    }
    
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        handleNavigationError(error, context: "didFail")
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handleNavigationError(error, context: "didFailProvisionalNavigation")
    }
    
    private func handleNavigationError(_ error: Error, context: String) {
        let nsError = error as NSError
        
        // Log the URL if available.
        if let urlStr = nsError.userInfo[NSURLErrorFailingURLStringErrorKey]
            as? String, let url = URL(string: urlStr)
        {
            Self.logger.debug(
                "Error (\(context)): \(url.absoluteString) - \(error.localizedDescription)"
            )
            self.currentURL = url
        } else {
            Self.logger.debug("Error (\(context)): \(error.localizedDescription)")
        }
        
        // Reset download check state on failure.
        blockDownloadCheckforURL = nil
        
        // NSURLErrorCancelled (-999) is common and often not a user-facing error.
        // It occurs when a new navigation interrupts an old one, or when we cancel for a download.
        if nsError.domain == NSURLErrorDomain
            && nsError.code == NSURLErrorCancelled
        {
            Self.logger.info("Navigation was cancelled (\(context)). This is often expected.")
            return
        }
        
        // Allow custom logic to ignore certain errors.
        if ErrorIgnoreManager.isURLErrorIgnored(error) { return }
        
        // Update the UI with the error.
        self.error = error
    }
    
    /// Parses the filename from a "Content-Disposition" header string.
    /// Handles both `filename="name"` and the modern `filename*=UTF-8''encoded-name` format.
    private func parseFilename(from contentDisposition: String) -> String? {
        let components = contentDisposition.split(separator: ";").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Prefer the modern UTF-8 format as it handles special characters correctly.
        for component in components {
            if component.lowercased().starts(with: "filename*=") {
                // e.g., filename*=UTF-8''example%20%C3%A4.zip
                if let encodedPart = component.split(separator: "''", maxSplits: 1).last {
                    return String(encodedPart).removingPercentEncoding
                }
            }
        }
        
        // Fallback to the older, simpler format.
        for component in components {
            if component.lowercased().starts(with: "filename=") {
                // e.g., filename="example.zip"
                var filename = component.dropFirst("filename=".count)
                if filename.hasPrefix("\"") && filename.hasSuffix("\"") {
                    filename = filename.dropFirst().dropLast()
                }
                return String(filename)
            }
        }
        
        return nil
    }
}
