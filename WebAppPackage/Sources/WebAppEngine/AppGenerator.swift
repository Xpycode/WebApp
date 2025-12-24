// AppGenerator.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation
import WebAppCore

/// Generates standalone web app bundles from a configuration.
///
/// The `AppGenerator` creates a fully functional macOS application bundle
/// by cloning the WebApp template and injecting the user's configuration.
/// The generated app operates in wrapper mode, displaying the configured website.
@MainActor
public final class AppGenerator {

    // MARK: - Singleton

    /// The shared app generator instance.
    public static let shared = AppGenerator()

    // MARK: - Properties

    /// The file manager used for file operations.
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {}

    // MARK: - App Generation

    /// Generates a standalone web app at the specified destination.
    ///
    /// This method:
    /// 1. Copies the app template to the destination
    /// 2. Updates the Info.plist with the app's name and bundle ID
    /// 3. Writes the WebAppConfig.plist with the user's configuration
    /// 4. Updates the app icon (if provided)
    ///
    /// - Parameters:
    ///   - configuration: The web app configuration.
    ///   - destination: The URL where the app should be created.
    /// - Throws: An error if generation fails.
    public func generateApp(
        configuration: WebAppConfiguration,
        destination: URL
    ) async throws {
        // Find the template app (this app itself)
        guard let templateURL = Bundle.main.bundleURL as URL? else {
            throw AppGeneratorError.templateNotFound
        }

        // Remove existing app at destination if present
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        // Copy the template app to destination
        try fileManager.copyItem(at: templateURL, to: destination)

        // Update the Info.plist
        try updateInfoPlist(at: destination, with: configuration)

        // Write the configuration file
        try writeConfiguration(configuration, to: destination)

        // Remove any code signing (it will need to be re-signed)
        try removeCodeSignature(at: destination)

        // Update the executable name if needed
        try updateExecutableName(at: destination, name: configuration.name)
    }

    // MARK: - Private Methods

    /// Updates the Info.plist with app-specific values.
    private func updateInfoPlist(at appURL: URL, with configuration: WebAppConfiguration) throws {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")

        guard var plist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] else {
            throw AppGeneratorError.infoPlistReadFailed
        }

        // Update app name and bundle identifier
        let sanitizedName = sanitizeBundleIdentifier(configuration.name)
        plist["CFBundleName"] = configuration.name
        plist["CFBundleDisplayName"] = configuration.name
        plist["CFBundleIdentifier"] = "com.xpycode.webapp.\(sanitizedName)"
        plist["CFBundleExecutable"] = "WebApp" // Keep the executable name

        // Write back
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try plistData.write(to: infoPlistURL)
    }

    /// Writes the WebAppConfig.plist file.
    private func writeConfiguration(_ configuration: WebAppConfiguration, to appURL: URL) throws {
        let configURL = appURL.appendingPathComponent("Contents/Resources/WebAppConfig.plist")

        // Ensure Resources directory exists
        let resourcesURL = appURL.appendingPathComponent("Contents/Resources")
        if !fileManager.fileExists(atPath: resourcesURL.path) {
            try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(configuration)
        try data.write(to: configURL)
    }

    /// Removes the code signature from the app bundle.
    private func removeCodeSignature(at appURL: URL) throws {
        let codeSignatureURL = appURL.appendingPathComponent("Contents/_CodeSignature")
        if fileManager.fileExists(atPath: codeSignatureURL.path) {
            try fileManager.removeItem(at: codeSignatureURL)
        }

        // Also remove embedded provisioning profile if present
        let provisioningURL = appURL.appendingPathComponent("Contents/embedded.provisionprofile")
        if fileManager.fileExists(atPath: provisioningURL.path) {
            try fileManager.removeItem(at: provisioningURL)
        }
    }

    /// Updates the executable name in the app bundle.
    private func updateExecutableName(at appURL: URL, name: String) throws {
        // For now, we keep the WebApp executable name
        // A more sophisticated approach would rename the binary
        // but that requires updating the Info.plist CFBundleExecutable
    }

    /// Sanitizes a string for use in a bundle identifier.
    private func sanitizeBundleIdentifier(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return name
            .components(separatedBy: allowed.inverted)
            .joined()
            .lowercased()
    }
}

// MARK: - Errors

/// Errors that can occur during app generation.
public enum AppGeneratorError: LocalizedError {
    case templateNotFound
    case infoPlistReadFailed
    case configurationWriteFailed
    case iconGenerationFailed

    public var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Could not find the app template. The WebApp application may be corrupted."
        case .infoPlistReadFailed:
            return "Failed to read the Info.plist file from the template."
        case .configurationWriteFailed:
            return "Failed to write the configuration file."
        case .iconGenerationFailed:
            return "Failed to generate the app icon."
        }
    }
}
