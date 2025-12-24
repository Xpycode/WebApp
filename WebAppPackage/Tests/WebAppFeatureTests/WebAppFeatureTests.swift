// WebAppFeatureTests.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Testing
import SwiftUI
@testable import WebAppFeature
@testable import WebAppCore

/// Tests for WebAppFeature views.
@Suite("WebAppFeature Tests")
struct WebAppFeatureTests {

    @Test("ContentView initializes successfully")
    func contentViewInitializes() {
        let view = ContentView()
        // Just verify it can be created without crashing
        #expect(type(of: view) == ContentView.self)
    }

    @Test("CreatorView initializes successfully")
    func creatorViewInitializes() {
        let view = CreatorView()
        #expect(type(of: view) == CreatorView.self)
    }

    @Test("WrapperView initializes with configuration")
    @MainActor
    func wrapperViewInitializes() {
        let config = WebAppConfiguration(
            name: "Test",
            homeURL: URL(string: "https://example.com")!
        )
        let view = WrapperView(configuration: config)
        #expect(type(of: view) == WrapperView.self)
    }
}
