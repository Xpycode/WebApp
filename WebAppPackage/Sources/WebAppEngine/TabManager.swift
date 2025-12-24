// TabManager.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation
import WebKit
import WebAppCore
import Observation

/// Manages a collection of web tabs for a browser window.
///
/// The `TabManager` provides functionality for creating, closing, and
/// navigating between tabs. It supports opening tabs in the background
/// and maintains the currently active tab.
@MainActor
@Observable
public final class TabManager {

    // MARK: - Properties

    /// The configuration for creating new tabs.
    public let configuration: WebAppConfiguration

    /// All open tabs.
    public private(set) var tabs: [WebTab] = []

    /// The currently active tab.
    public var activeTab: WebTab? {
        didSet {
            if let tab = activeTab, !tabs.contains(tab) {
                activeTab = tabs.first
            }
        }
    }

    /// Index of the active tab.
    public var activeTabIndex: Int? {
        get {
            guard let activeTab else { return nil }
            return tabs.firstIndex(of: activeTab)
        }
        set {
            if let index = newValue, tabs.indices.contains(index) {
                activeTab = tabs[index]
            }
        }
    }

    // MARK: - Initialization

    /// Creates a new tab manager with the specified configuration.
    ///
    /// - Parameter configuration: The web app configuration.
    /// - Parameter createInitialTab: Whether to create an initial tab. Defaults to `true`.
    public init(configuration: WebAppConfiguration, createInitialTab: Bool = true) {
        self.configuration = configuration

        if createInitialTab {
            let tab = WebTab(configuration: configuration)
            tabs.append(tab)
            activeTab = tab
        }
    }

    // MARK: - Tab Management

    /// Creates a new tab and optionally makes it active.
    ///
    /// - Parameters:
    ///   - url: The URL to load. Defaults to home URL if nil.
    ///   - inBackground: If true, the tab is created but not made active.
    /// - Returns: The newly created tab.
    @discardableResult
    public func createTab(with url: URL? = nil, inBackground: Bool = false) -> WebTab {
        let tab = WebTab(configuration: configuration, initialURL: url)
        tabs.append(tab)

        if !inBackground || activeTab == nil {
            activeTab = tab
        }

        return tab
    }

    /// Creates a new tab after the currently active tab.
    ///
    /// - Parameters:
    ///   - url: The URL to load.
    ///   - inBackground: If true, the tab is created but not made active.
    /// - Returns: The newly created tab.
    @discardableResult
    public func createTabAfterActive(with url: URL? = nil, inBackground: Bool = false) -> WebTab {
        let tab = WebTab(configuration: configuration, initialURL: url)

        if let activeIndex = activeTabIndex {
            tabs.insert(tab, at: activeIndex + 1)
        } else {
            tabs.append(tab)
        }

        if !inBackground || activeTab == nil {
            activeTab = tab
        }

        return tab
    }

    /// Closes the specified tab.
    ///
    /// - Parameter tab: The tab to close.
    public func closeTab(_ tab: WebTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }

        tabs.remove(at: index)

        // Update active tab if we closed the active one
        if activeTab == tab {
            if tabs.isEmpty {
                activeTab = nil
            } else if index < tabs.count {
                activeTab = tabs[index]
            } else {
                activeTab = tabs.last
            }
        }
    }

    /// Closes the tab at the specified index.
    ///
    /// - Parameter index: The index of the tab to close.
    public func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        closeTab(tabs[index])
    }

    /// Closes all tabs except the specified one.
    ///
    /// - Parameter tab: The tab to keep open.
    public func closeOtherTabs(except tab: WebTab) {
        tabs.removeAll { $0 != tab }
        activeTab = tab
    }

    /// Closes all tabs to the right of the specified tab.
    ///
    /// - Parameter tab: The reference tab.
    public func closeTabsToRight(of tab: WebTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }
        tabs.removeSubrange((index + 1)...)

        // Update active tab if it was closed
        if let active = activeTab, !tabs.contains(active) {
            activeTab = tab
        }
    }

    /// Moves a tab from one index to another.
    ///
    /// - Parameters:
    ///   - fromIndex: The current index of the tab.
    ///   - toIndex: The target index.
    public func moveTab(from fromIndex: Int, to toIndex: Int) {
        guard tabs.indices.contains(fromIndex),
              toIndex >= 0 && toIndex <= tabs.count else { return }

        let tab = tabs.remove(at: fromIndex)
        let adjustedIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        tabs.insert(tab, at: min(adjustedIndex, tabs.count))
    }

    // MARK: - Navigation

    /// Selects the next tab (wraps around).
    public func selectNextTab() {
        guard let currentIndex = activeTabIndex, !tabs.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % tabs.count
        activeTab = tabs[nextIndex]
    }

    /// Selects the previous tab (wraps around).
    public func selectPreviousTab() {
        guard let currentIndex = activeTabIndex, !tabs.isEmpty else { return }
        let prevIndex = currentIndex > 0 ? currentIndex - 1 : tabs.count - 1
        activeTab = tabs[prevIndex]
    }

    /// Selects the tab at the specified index (1-based for keyboard shortcuts).
    ///
    /// - Parameter number: The tab number (1-9, where 9 selects the last tab).
    public func selectTab(number: Int) {
        guard !tabs.isEmpty else { return }

        if number == 9 {
            // Cmd+9 selects last tab
            activeTab = tabs.last
        } else if number >= 1 && number <= tabs.count {
            activeTab = tabs[number - 1]
        }
    }

    /// Duplicates the specified tab.
    ///
    /// - Parameter tab: The tab to duplicate.
    /// - Returns: The new duplicated tab.
    @discardableResult
    public func duplicateTab(_ tab: WebTab) -> WebTab {
        createTabAfterActive(with: tab.url ?? configuration.homeURL, inBackground: false)
    }
}
