// WebTab.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation
import WebKit
import WebAppCore

/// Represents a single browser tab with its associated web view.
///
/// A `WebTab` manages the lifecycle of a `WKWebView` and provides
/// observable properties for the tab's state, including title, URL,
/// loading status, and navigation capabilities.
@MainActor
@Observable
public final class WebTab: Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier for this tab.
    public let id: UUID

    /// The configuration used to create this tab.
    public let configuration: WebAppConfiguration

    /// The underlying web view.
    public private(set) var webView: TabWebView

    /// Current page title.
    public private(set) var title: String = ""

    /// Current URL.
    public private(set) var url: URL?

    /// Whether the page is currently loading.
    public private(set) var isLoading: Bool = false

    /// Loading progress (0.0 to 1.0).
    public private(set) var loadingProgress: Double = 0.0

    /// Whether the tab can navigate back.
    public private(set) var canGoBack: Bool = false

    /// Whether the tab can navigate forward.
    public private(set) var canGoForward: Bool = false

    /// Favicon URL if available.
    public private(set) var faviconURL: URL?

    /// Creation timestamp.
    public let createdAt: Date

    /// The coordinator handling WebKit delegates.
    public private(set) var coordinator: WebViewCoordinator?

    // MARK: - Private Properties

    private var observations: [NSKeyValueObservation] = []

    // MARK: - Initialization

    /// Creates a new web tab with the specified configuration.
    ///
    /// - Parameters:
    ///   - configuration: The web app configuration.
    ///   - initialURL: Optional initial URL to load. Defaults to config's home URL.
    ///   - tabManager: Optional tab manager for handling new tab creation.
    public init(configuration: WebAppConfiguration, initialURL: URL? = nil, tabManager: TabManager? = nil) {
        self.id = UUID()
        self.configuration = configuration
        self.createdAt = Date()

        // Create web view configuration
        let webConfig = WKWebViewConfiguration()
        webConfig.defaultWebpagePreferences.allowsContentJavaScript = configuration.javaScriptEnabled

        // Configure preferences
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = configuration.javaScriptEnabled
        webConfig.defaultWebpagePreferences = prefs

        // Enable media capture if allowed
        webConfig.mediaTypesRequiringUserActionForPlayback = []

        // Enable link preview
        webConfig.preferences.isElementFullscreenEnabled = true

        // Create the web view
        self.webView = TabWebView(frame: .zero, configuration: webConfig)

        // Set up user agent if needed
        if let userAgentString = configuration.userAgent.userAgentString() {
            webView.customUserAgent = userAgentString
        }

        // Allow magnification (zoom)
        webView.allowsMagnification = true

        // Set up the coordinator for delegate handling
        let coord = WebViewCoordinator(configuration: configuration, tab: self, tabManager: tabManager)
        self.coordinator = coord
        webView.navigationDelegate = coord
        webView.uiDelegate = coord

        // Wire up context menu "Open in New Tab" callback
        webView.onOpenInNewTab = { [weak tabManager] url, inBackground in
            tabManager?.createTab(with: url, inBackground: inBackground)
        }

        // Set up observations
        setupObservations()

        // Load initial URL
        let urlToLoad = initialURL ?? configuration.homeURL
        webView.load(URLRequest(url: urlToLoad))
    }

    // MARK: - Coordinator Setup

    /// Updates the tab manager reference in the coordinator.
    ///
    /// - Parameter tabManager: The tab manager to use.
    public func setTabManager(_ tabManager: TabManager) {
        coordinator?.tabManager = tabManager
    }

    // Note: observations are automatically invalidated when the WebTab is deallocated

    // MARK: - Navigation

    /// Loads the specified URL.
    ///
    /// - Parameter url: The URL to load.
    public func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    /// Reloads the current page.
    public func reload() {
        webView.reload()
    }

    /// Navigates back in history.
    public func goBack() {
        webView.goBack()
    }

    /// Navigates forward in history.
    public func goForward() {
        webView.goForward()
    }

    /// Stops the current load.
    public func stopLoading() {
        webView.stopLoading()
    }

    /// Navigates to the home URL.
    public func goHome() {
        load(configuration.homeURL)
    }

    // MARK: - Private Methods

    private func setupObservations() {
        // Observe title
        observations.append(webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.title = webView.title ?? ""
            }
        })

        // Observe URL
        observations.append(webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.url = webView.url
            }
        })

        // Observe loading state
        observations.append(webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.isLoading = webView.isLoading
            }
        })

        // Observe loading progress
        observations.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.loadingProgress = webView.estimatedProgress
            }
        })

        // Observe navigation capabilities
        observations.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoBack = webView.canGoBack
            }
        })

        observations.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoForward = webView.canGoForward
            }
        })
    }

    // MARK: - Hashable & Equatable

    public nonisolated static func == (lhs: WebTab, rhs: WebTab) -> Bool {
        lhs.id == rhs.id
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
