// TabManagerTests.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Testing
import Foundation
@testable import WebAppEngine
@testable import WebAppCore

/// Tests for TabManager.
@Suite("TabManager Tests")
@MainActor
struct TabManagerTests {

    /// Creates a test configuration.
    private func makeConfiguration() -> WebAppConfiguration {
        WebAppConfiguration(
            name: "Test",
            homeURL: URL(string: "https://example.com")!
        )
    }

    @Test("TabManager creates initial tab by default")
    func createsInitialTab() {
        let manager = TabManager(configuration: makeConfiguration())

        #expect(manager.tabs.count == 1)
        #expect(manager.activeTab != nil)
    }

    @Test("TabManager can be created without initial tab")
    func createsWithoutInitialTab() {
        let manager = TabManager(configuration: makeConfiguration(), createInitialTab: false)

        #expect(manager.tabs.isEmpty)
        #expect(manager.activeTab == nil)
    }

    @Test("Creating a tab adds it to the list")
    func createTabAddsToList() {
        let manager = TabManager(configuration: makeConfiguration(), createInitialTab: false)

        let tab = manager.createTab()

        #expect(manager.tabs.count == 1)
        #expect(manager.tabs.contains(tab))
        #expect(manager.activeTab == tab)
    }

    @Test("Creating a background tab doesn't change active tab")
    func backgroundTabDoesNotActivate() {
        let manager = TabManager(configuration: makeConfiguration())
        let initialTab = manager.activeTab

        _ = manager.createTab(inBackground: true)

        #expect(manager.tabs.count == 2)
        #expect(manager.activeTab == initialTab)
    }

    @Test("Closing active tab selects next tab")
    func closingActiveTabSelectsNext() {
        let manager = TabManager(configuration: makeConfiguration())
        let tab2 = manager.createTab()
        let tab3 = manager.createTab()

        manager.activeTab = tab2
        manager.closeTab(tab2)

        #expect(manager.tabs.count == 2)
        #expect(manager.activeTab == tab3)
    }

    @Test("Closing last tab selects previous")
    func closingLastTabSelectsPrevious() {
        let manager = TabManager(configuration: makeConfiguration())
        let tab1 = manager.tabs[0]
        let tab2 = manager.createTab()

        manager.activeTab = tab2
        manager.closeTab(tab2)

        #expect(manager.tabs.count == 1)
        #expect(manager.activeTab == tab1)
    }

    @Test("Select next tab wraps around")
    func selectNextTabWraps() {
        let manager = TabManager(configuration: makeConfiguration())
        let tab1 = manager.tabs[0]
        _ = manager.createTab()
        let tab3 = manager.createTab()

        manager.activeTab = tab3
        manager.selectNextTab()

        #expect(manager.activeTab == tab1)
    }

    @Test("Select previous tab wraps around")
    func selectPreviousTabWraps() {
        let manager = TabManager(configuration: makeConfiguration())
        let tab1 = manager.tabs[0]
        _ = manager.createTab()
        let tab3 = manager.createTab()

        manager.activeTab = tab1
        manager.selectPreviousTab()

        #expect(manager.activeTab == tab3)
    }

    @Test("Select tab by number works correctly")
    func selectTabByNumber() {
        let manager = TabManager(configuration: makeConfiguration())
        let tab1 = manager.tabs[0]
        let tab2 = manager.createTab()
        let tab3 = manager.createTab()

        manager.selectTab(number: 2)
        #expect(manager.activeTab == tab2)

        manager.selectTab(number: 1)
        #expect(manager.activeTab == tab1)

        // Cmd+9 selects last tab
        manager.selectTab(number: 9)
        #expect(manager.activeTab == tab3)
    }
}
