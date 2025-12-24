// WebAppConfigurationTests.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Testing
import Foundation
@testable import WebAppCore

/// Tests for WebAppConfiguration.
@Suite("WebAppConfiguration Tests")
struct WebAppConfigurationTests {

    @Test("Configuration initializes with required values")
    func initializesWithRequiredValues() {
        let config = WebAppConfiguration(
            name: "Test App",
            homeURL: URL(string: "https://example.com")!
        )

        #expect(config.name == "Test App")
        #expect(config.homeURL.absoluteString == "https://example.com")
        #expect(config.javaScriptEnabled == true)
        #expect(config.showNavigationBar == false)
    }

    @Test("Configuration encodes and decodes correctly")
    func encodesAndDecodes() throws {
        let original = WebAppConfiguration(
            name: "YouTube",
            homeURL: URL(string: "https://youtube.com")!,
            userAgent: .desktop,
            showNavigationBar: false
        )

        let data = try original.encodeToPlist()
        let decoded = try PropertyListDecoder().decode(WebAppConfiguration.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.homeURL == original.homeURL)
        #expect(decoded.userAgent == original.userAgent)
        #expect(decoded.showNavigationBar == original.showNavigationBar)
    }

    @Test("Effective bundle identifier generates correctly")
    func effectiveBundleIdentifier() {
        let config1 = WebAppConfiguration(
            name: "My App",
            homeURL: URL(string: "https://example.com")!,
            bundleIdentifier: "com.custom.bundle"
        )
        #expect(config1.effectiveBundleIdentifier == "com.custom.bundle")

        let config2 = WebAppConfiguration(
            name: "YouTube TV",
            homeURL: URL(string: "https://tv.youtube.com")!
        )
        #expect(config2.effectiveBundleIdentifier == "com.xpycode.webapp.youtube-tv")
    }

    @Test("Home domain extracts correctly")
    func homeDomainExtraction() {
        let config = WebAppConfiguration(
            name: "GitHub",
            homeURL: URL(string: "https://github.com/user/repo")!
        )
        #expect(config.homeDomain == "github.com")
    }
}

/// Tests for AppMode.
@Suite("AppMode Tests")
struct AppModeTests {

    @Test("Creator mode is detected when no config exists")
    func creatorModeDetection() {
        // In test environment, no config file exists
        let mode = AppMode.detect()
        #expect(mode.isCreator)
        #expect(!mode.isWrapper)
        #expect(mode.configuration == nil)
    }
}

/// Tests for UserAgentMode.
@Suite("UserAgentMode Tests")
struct UserAgentModeTests {

    @Test("Desktop mode returns nil (uses default)")
    func desktopMode() {
        let mode = UserAgentMode.desktop
        #expect(mode.userAgentString() == nil)
    }

    @Test("Mobile mode returns mobile user agent")
    func mobileMode() {
        let mode = UserAgentMode.mobile
        let userAgent = mode.userAgentString()
        #expect(userAgent != nil)
        #expect(userAgent!.contains("iPhone"))
    }
}
