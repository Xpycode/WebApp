// WebViewCoordinator.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation
import WebKit
import AppKit
import WebAppCore

/// Coordinator that handles WebKit delegate callbacks for a WebTab.
///
/// This class implements `WKNavigationDelegate` and `WKUIDelegate` to handle:
/// - Navigation decisions (allow/deny, external links)
/// - New window/tab requests
/// - JavaScript alerts and prompts
/// - Download handling
/// - Authentication challenges
@MainActor
public final class WebViewCoordinator: NSObject {

    // MARK: - Properties

    /// The tab this coordinator manages.
    public weak var tab: WebTab?

    /// The tab manager for creating new tabs.
    public weak var tabManager: TabManager?

    /// The configuration for navigation decisions.
    public let configuration: WebAppConfiguration

    // MARK: - Initialization

    /// Creates a new coordinator with the specified configuration.
    ///
    /// - Parameters:
    ///   - configuration: The web app configuration.
    ///   - tab: The tab to coordinate.
    ///   - tabManager: The tab manager for new tab creation.
    public init(
        configuration: WebAppConfiguration,
        tab: WebTab? = nil,
        tabManager: TabManager? = nil
    ) {
        self.configuration = configuration
        self.tab = tab
        self.tabManager = tabManager
        super.init()
    }

    // MARK: - Private Helpers

    /// Checks if a URL is within the allowed domain.
    private func isInternalURL(_ url: URL) -> Bool {
        guard let homeDomain = configuration.homeDomain,
              let urlHost = url.host else {
            return true // Allow if we can't determine
        }

        // Check if the URL host matches or is a subdomain of the home domain
        return urlHost == homeDomain || urlHost.hasSuffix(".\(homeDomain)")
    }

    /// Opens a URL in the default browser.
    private func openInBrowser(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewCoordinator: WKNavigationDelegate {

    /// Decides whether to allow or cancel a navigation.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Always allow about: and javascript: URLs
        if url.scheme == "about" || url.scheme == "javascript" {
            decisionHandler(.allow)
            return
        }

        // Handle external links based on configuration
        if !isInternalURL(url) {
            switch configuration.externalLinkBehavior {
            case .openInDefaultBrowser:
                openInBrowser(url)
                decisionHandler(.cancel)

            case .openInNewTab:
                if let tabManager = tabManager {
                    // Check if it's a user-initiated click (not a redirect)
                    let inBackground = navigationAction.modifierFlags.contains(.command)
                    tabManager.createTab(with: url, inBackground: inBackground)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }

            case .block:
                decisionHandler(.cancel)

            case .allowInPlace:
                decisionHandler(.allow)
            }
            return
        }

        // Check allowed URL patterns if configured
        if !configuration.allowedURLPatterns.isEmpty {
            let urlString = url.absoluteString
            let isAllowed = configuration.allowedURLPatterns.contains { pattern in
                urlString.range(of: pattern, options: .regularExpression) != nil
            }
            if !isAllowed {
                decisionHandler(.cancel)
                return
            }
        }

        // Handle target="_blank" links
        if navigationAction.targetFrame == nil {
            // This is a new window request, handle based on click modifiers
            if let tabManager = tabManager {
                let inBackground = navigationAction.modifierFlags.contains(.command)
                tabManager.createTab(with: url, inBackground: inBackground)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    /// Called when navigation starts.
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Navigation started - loading indicator will be shown via observations
    }

    /// Called when content starts loading.
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Content loading started
    }

    /// Called when navigation completes successfully.
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Navigation completed successfully
    }

    /// Called when navigation fails.
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Log navigation failure
        print("⚠️ WebApp: Navigation failed: \(error.localizedDescription)")
    }

    /// Called when provisional navigation fails.
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Handle common errors gracefully
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorCancelled:
            // User cancelled, ignore
            break
        case NSURLErrorNotConnectedToInternet:
            print("⚠️ WebApp: No internet connection")
        default:
            print("⚠️ WebApp: Provisional navigation failed: \(error.localizedDescription)")
        }
    }

    /// Handles authentication challenges.
    public func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Use default handling for server trust
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - WKUIDelegate

extension WebViewCoordinator: WKUIDelegate {

    /// Handles requests to create a new web view (new window/tab).
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Handle new window requests by creating a new tab
        if let url = navigationAction.request.url, let tabManager = tabManager {
            let inBackground = navigationAction.modifierFlags.contains(.command)
            tabManager.createTab(with: url, inBackground: inBackground)
        }
        return nil // We handle this ourselves, don't create a new WKWebView
    }

    /// Handles JavaScript alert panels.
    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = frame.request.url?.host ?? "Alert"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    /// Handles JavaScript confirm panels.
    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = frame.request.url?.host ?? "Confirm"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }

    /// Handles JavaScript prompt panels.
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = frame.request.url?.host ?? "Input"
        alert.informativeText = prompt
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(textField.stringValue)
        } else {
            completionHandler(nil)
        }
    }
}
