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
/// - Tab bar with tab management
/// - WebKit-based web content display
/// - Optional navigation controls
public struct WrapperView: View {

    // MARK: - Properties

    /// The web app configuration.
    let configuration: WebAppConfiguration

    /// The tab manager for this window.
    @State private var tabManager: TabManager

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
            TabBarView(tabManager: tabManager)

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

            Button("New Tab") {
                tabManager.createTab()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Tab Bar View

/// The tab bar showing all open tabs.
struct TabBarView: View {
    @Bindable var tabManager: TabManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isActive: tabManager.activeTab == tab,
                        onSelect: { tabManager.activeTab = tab },
                        onClose: { tabManager.closeTab(tab) }
                    )
                }

                // New Tab Button
                Button {
                    tabManager.createTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Tab Item View

/// A single tab in the tab bar.
struct TabItemView: View {
    let tab: WebTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Loading indicator or favicon
            if tab.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)

            // Close button
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .onHover { isHovering = $0 }
        .onTapGesture { onSelect() }
    }
}

// MARK: - Navigation Bar View

/// The navigation bar with URL and controls.
struct NavigationBarView: View {
    let tab: WebTab

    var body: some View {
        HStack(spacing: 12) {
            // Back
            Button {
                tab.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!tab.canGoBack)

            // Forward
            Button {
                tab.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!tab.canGoForward)

            // Reload
            Button {
                if tab.isLoading {
                    tab.stopLoading()
                } else {
                    tab.reload()
                }
            } label: {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
            }

            // URL display
            HStack {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(tab.url?.host ?? "")
                    .font(.system(size: 13))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Home
            Button {
                tab.goHome()
            } label: {
                Image(systemName: "house")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - WebView Container

/// Container for the WKWebView.
struct WebViewContainer: NSViewRepresentable {
    let tab: WebTab

    func makeNSView(context: Context) -> WKWebView {
        tab.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // View updates are handled by the tab's observations
    }
}

// MARK: - Preview

#Preview {
    WrapperView(configuration: WebAppConfiguration(
        name: "Example",
        homeURL: URL(string: "https://apple.com")!
    ))
}
