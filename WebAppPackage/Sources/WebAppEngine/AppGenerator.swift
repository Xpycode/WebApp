// AppGenerator.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation
import AppKit
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

        // Generate and set the app icon
        try generateAppIcon(for: configuration, at: destination)

        // Ad-hoc sign the app so macOS doesn't block it
        try signApp(at: destination)
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

    /// Signs the app with an ad-hoc signature so macOS doesn't block it.
    private func signApp(at appURL: URL) throws {
        // First clear quarantine attributes
        let xattrProcess = Process()
        xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        xattrProcess.arguments = ["-cr", appURL.path]
        try xattrProcess.run()
        xattrProcess.waitUntilExit()

        // Then ad-hoc sign the app
        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["--force", "--deep", "--sign", "-", appURL.path]
        try codesignProcess.run()
        codesignProcess.waitUntilExit()

        if codesignProcess.terminationStatus != 0 {
            throw AppGeneratorError.codeSigningFailed
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

    // MARK: - Icon Generation

    /// Generates an app icon for the configuration.
    private func generateAppIcon(for configuration: WebAppConfiguration, at appURL: URL) throws {
        let resourcesURL = appURL.appendingPathComponent("Contents/Resources")
        let iconURL = resourcesURL.appendingPathComponent("AppIcon.icns")

        // Generate icon images at required sizes
        let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
        var iconImages: [NSImage] = []

        for size in sizes {
            if let image = createIconImage(
                name: configuration.name,
                size: CGFloat(size)
            ) {
                iconImages.append(image)
            }
        }

        guard !iconImages.isEmpty else {
            throw AppGeneratorError.iconGenerationFailed
        }

        // Create the icns file
        try createIconFile(from: iconImages, at: iconURL, name: configuration.name)

        // Update Info.plist to use this icon
        try updateInfoPlistIcon(at: appURL)
    }

    /// Creates an icon image with the app's initial letter.
    private func createIconImage(name: String, size: CGFloat) -> NSImage? {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()
        defer { image.unlockFocus() }

        guard let context = NSGraphicsContext.current?.cgContext else {
            return nil
        }

        // Draw rounded rectangle with gradient
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.22 // macOS app icon corner radius ratio
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Create gradient
        let colors = [
            NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,
            NSColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else {
            return nil
        }

        context.saveGState()
        context.addPath(path)
        context.clip()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size),
            end: CGPoint(x: size, y: 0),
            options: []
        )
        context.restoreGState()

        // Draw the letter
        let letter = String(name.prefix(1)).uppercased()
        let fontSize = size * 0.5
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]

        let attributedString = NSAttributedString(string: letter, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: (size - textSize.width) / 2,
            y: (size - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)

        return image
    }

    /// Creates an icns file from the provided images.
    private func createIconFile(from images: [NSImage], at url: URL, name: String) throws {
        // Create an iconset directory
        let iconsetURL = url.deletingLastPathComponent().appendingPathComponent("AppIcon.iconset")

        if fileManager.fileExists(atPath: iconsetURL.path) {
            try fileManager.removeItem(at: iconsetURL)
        }
        try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

        // Icon sizes and their names for iconset
        let iconSizes: [(size: Int, scale: Int, suffix: String)] = [
            (16, 1, "icon_16x16.png"),
            (16, 2, "icon_16x16@2x.png"),
            (32, 1, "icon_32x32.png"),
            (32, 2, "icon_32x32@2x.png"),
            (128, 1, "icon_128x128.png"),
            (128, 2, "icon_128x128@2x.png"),
            (256, 1, "icon_256x256.png"),
            (256, 2, "icon_256x256@2x.png"),
            (512, 1, "icon_512x512.png"),
            (512, 2, "icon_512x512@2x.png")
        ]

        // Write images to iconset
        for iconSize in iconSizes {
            let pixelSize = iconSize.size * iconSize.scale
            if let image = createIconImage(name: name, size: CGFloat(pixelSize)) {
                let imageURL = iconsetURL.appendingPathComponent(iconSize.suffix)
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try pngData.write(to: imageURL)
                }
            }
        }

        // Use iconutil to create the icns file
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetURL.path, "-o", url.path]

        try process.run()
        process.waitUntilExit()

        // Clean up iconset
        try? fileManager.removeItem(at: iconsetURL)

        if process.terminationStatus != 0 {
            throw AppGeneratorError.iconGenerationFailed
        }
    }

    /// Updates Info.plist to reference the generated icon.
    private func updateInfoPlistIcon(at appURL: URL) throws {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")

        guard var plist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] else {
            throw AppGeneratorError.infoPlistReadFailed
        }

        plist["CFBundleIconFile"] = "AppIcon"
        plist["CFBundleIconName"] = "AppIcon"

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try plistData.write(to: infoPlistURL)
    }
}

// MARK: - Errors

/// Errors that can occur during app generation.
public enum AppGeneratorError: LocalizedError {
    case templateNotFound
    case infoPlistReadFailed
    case configurationWriteFailed
    case iconGenerationFailed
    case codeSigningFailed

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
        case .codeSigningFailed:
            return "Failed to sign the generated app. The app may not open correctly."
        }
    }
}
