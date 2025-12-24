// AppMode.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation

/// Represents the operating mode of the WebApp application.
///
/// The app can run in two modes:
/// - **Creator Mode**: The main factory app where users create new web apps.
/// - **Wrapper Mode**: A generated app that wraps a specific website.
///
/// The mode is determined by the presence of a `WebAppConfig.plist` file
/// in the app bundle's Resources folder.
public enum AppMode: Sendable, Equatable {
    /// Creator mode - the factory app for creating new web apps.
    case creator

    /// Wrapper mode - a generated app wrapping a specific website.
    case wrapper(WebAppConfiguration)

    // MARK: - Configuration File Constants

    /// The filename for the embedded configuration in wrapper apps.
    public static let configFileName = "WebAppConfig.plist"

    // MARK: - Mode Detection

    /// Detects the current app mode based on bundle contents.
    ///
    /// This method checks for the presence of `WebAppConfig.plist` in the
    /// main bundle. If found and valid, the app runs in wrapper mode with
    /// the loaded configuration. Otherwise, it runs in creator mode.
    ///
    /// - Returns: The detected app mode.
    public static func detect() -> AppMode {
        // Check for embedded configuration
        guard let configURL = Bundle.main.url(forResource: "WebAppConfig", withExtension: "plist") else {
            return .creator
        }

        // Try to load the configuration
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = PropertyListDecoder()
            let configuration = try decoder.decode(WebAppConfiguration.self, from: data)
            return .wrapper(configuration)
        } catch {
            // If config exists but is invalid, log error and fall back to creator mode
            print("⚠️ WebApp: Failed to load configuration from \(configURL): \(error)")
            return .creator
        }
    }

    // MARK: - Convenience Properties

    /// Whether the app is running in creator mode.
    public var isCreator: Bool {
        if case .creator = self { return true }
        return false
    }

    /// Whether the app is running in wrapper mode.
    public var isWrapper: Bool {
        if case .wrapper = self { return true }
        return false
    }

    /// The configuration if running in wrapper mode, nil otherwise.
    public var configuration: WebAppConfiguration? {
        if case .wrapper(let config) = self { return config }
        return nil
    }
}

// MARK: - Configuration Saving

extension WebAppConfiguration {
    /// Encodes the configuration to property list data.
    ///
    /// - Returns: The encoded property list data.
    /// - Throws: An error if encoding fails.
    public func encodeToPlist() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        return try encoder.encode(self)
    }

    /// Saves the configuration to a file at the specified URL.
    ///
    /// - Parameter url: The file URL to save to.
    /// - Throws: An error if saving fails.
    public func save(to url: URL) throws {
        let data = try encodeToPlist()
        try data.write(to: url, options: .atomic)
    }

    /// Loads a configuration from a file at the specified URL.
    ///
    /// - Parameter url: The file URL to load from.
    /// - Returns: The loaded configuration.
    /// - Throws: An error if loading fails.
    public static func load(from url: URL) throws -> WebAppConfiguration {
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try decoder.decode(WebAppConfiguration.self, from: data)
    }
}
