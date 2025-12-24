// WrapperView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebKit
import WebAppCore
import WebAppEngine

/// The main view for the WebApp Wrapper - displays the wrapped website.
///
/// This view provides:
/// - Tab bar with tab management and context menus
/// - WebKit-based web content display
/// - Loading progress indicator
/// - Optional navigation controls
/// - Keyboard shortcuts for tab management
public struct WrapperView: View {

    // MARK: - Properties

    /// The web app configuration.
    let configuration: WebAppConfiguration

    /// The tab manager for this window.
    @State private var tabManager: TabManager

    /// Stack of recently closed tab URLs for "reopen closed tab" feature.
    @State private var recentlyClosedTabs: [URL] = []

    // MARK: - Initialization

    /// Creates a new wrapper view with the specified configuration.
    ///
    /// - Parameter configuration: The web app configuration.
    public init(configuration: WebAppConfiguration) {
        self.configuration = configuration
        self._tabManager = State(initialValue: TabManager(configuration: configuration))
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            TabBarView(
                tabManager: tabManager,
                onCloseTab: { tab in closeTab(tab) },
                onReopenTab: reopenClosedTab,
                canReopenTab: !recentlyClosedTabs.isEmpty
            )

            // Loading Progress Bar
            if let activeTab = tabManager.activeTab, activeTab.isLoading {
                LoadingProgressBar(progress: activeTab.loadingProgress)
            }

            // Navigation Bar (if enabled)
            if configuration.showNavigationBar, let activeTab = tabManager.activeTab {
                NavigationBarView(tab: activeTab)
            }

            // Web Content
            if let activeTab = tabManager.activeTab {
                WebViewContainer(tab: activeTab)
            } else {
                emptyStateView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        // Menu command handlers
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.newTab"))) { _ in
            tabManager.createTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.closeTab"))) { _ in
            if let activeTab = tabManager.activeTab {
                closeTab(activeTab)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.reopenClosedTab"))) { _ in
            reopenClosedTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.nextTab"))) { _ in
            tabManager.selectNextTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.previousTab"))) { _ in
            tabManager.selectPreviousTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.selectTab"))) { notification in
            if let number = notification.userInfo?["number"] as? Int {
                tabManager.selectTab(number: number)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.navigateBack"))) { _ in
            tabManager.activeTab?.goBack()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.navigateForward"))) { _ in
            tabManager.activeTab?.goForward()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.reloadPage"))) { _ in
            tabManager.activeTab?.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("com.xpycode.webapp.goHome"))) { _ in
            tabManager.activeTab?.goHome()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No tabs open")
                .font(.title2)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("New Tab") {
                    tabManager.createTab()
                }
                .buttonStyle(.borderedProminent)

                if !recentlyClosedTabs.isEmpty {
                    Button("Reopen Closed Tab") {
                        reopenClosedTab()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Tab Actions

    private func closeTab(_ tab: WebTab) {
        // Save URL for reopening
        if let url = tab.url {
            recentlyClosedTabs.append(url)
            // Keep only last 10 closed tabs
            if recentlyClosedTabs.count > 10 {
                recentlyClosedTabs.removeFirst()
            }
        }
        tabManager.closeTab(tab)
    }

    private func reopenClosedTab() {
        guard let url = recentlyClosedTabs.popLast() else { return }
        tabManager.createTab(with: url)
    }
}

// MARK: - Loading Progress Bar

/// A thin progress bar shown below the tab bar during page loads.
struct LoadingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: geometry.size.width * progress)
                .animation(.linear(duration: 0.1), value: progress)
        }
        .frame(height: 2)
        .background(Color(nsColor: .separatorColor))
    }
}

// MARK: - Tab Bar View

/// The tab bar showing all open tabs with context menu support.
struct TabBarView: View {
    @Bindable var tabManager: TabManager
    let onCloseTab: (WebTab) -> Void
    let onReopenTab: () -> Void
    let canReopenTab: Bool

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tabManager.activeTab == tab,
                            isOnlyTab: tabManager.tabs.count == 1,
                            onSelect: { tabManager.activeTab = tab },
                            onClose: { onCloseTab(tab) }
                        )
                        .contextMenu {
                            tabContextMenu(for: tab)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            Divider()
                .frame(height: 20)

            // New Tab Button
            Button {
                tabManager.createTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func tabContextMenu(for tab: WebTab) -> some View {
        Button("New Tab") {
            tabManager.createTab()
        }

        Button("Duplicate Tab") {
            tabManager.duplicateTab(tab)
        }

        Divider()

        if canReopenTab {
            Button("Reopen Closed Tab") {
                onReopenTab()
            }
        }

        Divider()

        Button("Reload") {
            tab.reload()
        }

        Divider()

        Button("Close Tab") {
            onCloseTab(tab)
        }
        .disabled(tabManager.tabs.count == 1)

        Button("Close Other Tabs") {
            // Close all except this one
            for otherTab in tabManager.tabs where otherTab != tab {
                onCloseTab(otherTab)
            }
        }
        .disabled(tabManager.tabs.count <= 1)

        Button("Close Tabs to the Right") {
            if let index = tabManager.tabs.firstIndex(of: tab) {
                let tabsToClose = Array(tabManager.tabs.suffix(from: index + 1))
                for tabToClose in tabsToClose {
                    onCloseTab(tabToClose)
                }
            }
        }
        .disabled(tabManager.tabs.last == tab)
    }
}

// MARK: - Tab Item View

/// A single tab in the tab bar with improved styling.
struct TabItemView: View {
    let tab: WebTab
    let isActive: Bool
    let isOnlyTab: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering: Bool = false

    private var backgroundColor: Color {
        if isActive {
            return Color(nsColor: .controlBackgroundColor)
        } else if isHovering {
            return Color(nsColor: .controlBackgroundColor).opacity(0.5)
        } else {
            return Color.clear
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Loading indicator or favicon
            ZStack {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.4)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 14, height: 14)

            // Title
            Text(displayTitle)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: 140, alignment: .leading)
                .foregroundStyle(isActive ? .primary : .secondary)

            // Close button (hidden for single tab)
            if !isOnlyTab {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .opacity(isHovering ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .opacity(isHovering || isActive ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(nsColor: .separatorColor).opacity(isActive ? 0.5 : 0), lineWidth: 0.5)
        )
        .onHover { isHovering = $0 }
        .onTapGesture { onSelect() }
    }

    private var displayTitle: String {
        if tab.title.isEmpty {
            if let host = tab.url?.host {
                return host
            }
            return "New Tab"
        }
        return tab.title
    }
}

// MARK: - Navigation Bar View

/// The navigation bar with URL and controls.
struct NavigationBarView: View {
    let tab: WebTab

    var body: some View {
        HStack(spacing: 8) {
            // Navigation buttons
            HStack(spacing: 4) {
                NavigationButton(
                    systemName: "chevron.left",
                    action: { tab.goBack() },
                    isEnabled: tab.canGoBack,
                    help: "Back (⌘[)"
                )

                NavigationButton(
                    systemName: "chevron.right",
                    action: { tab.goForward() },
                    isEnabled: tab.canGoForward,
                    help: "Forward (⌘])"
                )

                NavigationButton(
                    systemName: tab.isLoading ? "xmark" : "arrow.clockwise",
                    action: {
                        if tab.isLoading {
                            tab.stopLoading()
                        } else {
                            tab.reload()
                        }
                    },
                    isEnabled: true,
                    help: tab.isLoading ? "Stop" : "Reload (⌘R)"
                )
            }

            // URL display
            HStack(spacing: 6) {
                if let url = tab.url, url.scheme == "https" {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }

                Text(tab.url?.host ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Home button
            NavigationButton(
                systemName: "house",
                action: { tab.goHome() },
                isEnabled: true,
                help: "Home (⌘⇧H)"
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// A styled navigation button.
struct NavigationButton: View {
    let systemName: String
    let action: () -> Void
    let isEnabled: Bool
    let help: String

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(help)
    }
}

// MARK: - WebView Container

/// Container for the TabWebView (custom WKWebView with context menu support).
struct WebViewContainer: NSViewRepresentable {
    let tab: WebTab

    func makeNSView(context: Context) -> TabWebView {
        let webView = tab.webView
        // Ensure the web view fills the container
        webView.autoresizingMask = [.width, .height]
        return webView
    }

    func updateNSView(_ nsView: TabWebView, context: Context) {
        // View updates are handled by the tab's observations
    }
}

// MARK: - Preview

#Preview("Wrapper View") {
    WrapperView(configuration: WebAppConfiguration(
        name: "Example",
        homeURL: URL(string: "https://apple.com")!
    ))
}

#Preview("Wrapper with Nav Bar") {
    WrapperView(configuration: WebAppConfiguration(
        name: "Example",
        homeURL: URL(string: "https://apple.com")!,
        showNavigationBar: true
    ))
}
