// WebAppConfiguration.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import Foundation

/// Configuration model for a WebApp instance.
///
/// This configuration determines how the wrapper app behaves, including
/// the target URL, app name, appearance settings, and behavior options.
///
/// When a generated app is created, this configuration is embedded in the
/// app bundle and loaded at launch to configure the web wrapper.
public struct WebAppConfiguration: Codable, Sendable, Equatable, Hashable {

    // MARK: - Identity

    /// Unique identifier for this web app configuration.
    public var id: UUID

    /// Display name of the web app (shown in Dock, menu bar, etc.).
    public var name: String

    /// The primary URL to load when the app launches.
    public var homeURL: URL

    /// Optional custom bundle identifier for the generated app.
    /// If nil, a default will be generated based on the name.
    public var bundleIdentifier: String?

    // MARK: - Appearance

    /// Custom user agent string. If nil, uses WebKit default.
    public var userAgent: UserAgentMode

    /// Whether to show the navigation bar with URL and controls.
    public var showNavigationBar: Bool

    /// Window title mode.
    public var windowTitleMode: WindowTitleMode

    // MARK: - Behavior

    /// How to handle links that navigate away from the home domain.
    public var externalLinkBehavior: ExternalLinkBehavior

    /// Allowed URL patterns (regex). If empty, allows all.
    public var allowedURLPatterns: [String]

    /// Whether to enable JavaScript.
    public var javaScriptEnabled: Bool

    /// Whether to block pop-ups.
    public var blockPopups: Bool

    /// Whether cookies should persist across sessions.
    public var persistCookies: Bool

    /// Whether to enable web notifications.
    public var notificationsEnabled: Bool

    /// Whether to allow camera access.
    public var cameraAccessEnabled: Bool

    /// Whether to allow microphone access.
    public var microphoneAccessEnabled: Bool

    // MARK: - Window Settings

    /// Default window size when launching.
    public var defaultWindowSize: CGSize?

    /// Minimum window size.
    public var minimumWindowSize: CGSize?

    // MARK: - Initialization

    /// Creates a new web app configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided).
    ///   - name: Display name of the web app.
    ///   - homeURL: The primary URL to load.
    ///   - bundleIdentifier: Optional custom bundle identifier.
    ///   - userAgent: User agent mode (defaults to `.desktop`).
    ///   - showNavigationBar: Whether to show navigation bar (defaults to `false`).
    ///   - windowTitleMode: How to set window title (defaults to `.pageTitle`).
    ///   - externalLinkBehavior: How to handle external links (defaults to `.openInDefaultBrowser`).
    ///   - allowedURLPatterns: Allowed URL patterns (defaults to empty, allowing all).
    ///   - javaScriptEnabled: Whether JavaScript is enabled (defaults to `true`).
    ///   - blockPopups: Whether to block pop-ups (defaults to `false`).
    ///   - persistCookies: Whether cookies persist (defaults to `true`).
    ///   - notificationsEnabled: Whether notifications are enabled (defaults to `true`).
    ///   - cameraAccessEnabled: Whether camera access is allowed (defaults to `true`).
    ///   - microphoneAccessEnabled: Whether microphone access is allowed (defaults to `true`).
    ///   - defaultWindowSize: Default window size (defaults to `nil`).
    ///   - minimumWindowSize: Minimum window size (defaults to `nil`).
    public init(
        id: UUID = UUID(),
        name: String,
        homeURL: URL,
        bundleIdentifier: String? = nil,
        userAgent: UserAgentMode = .desktop,
        showNavigationBar: Bool = false,
        windowTitleMode: WindowTitleMode = .pageTitle,
        externalLinkBehavior: ExternalLinkBehavior = .openInDefaultBrowser,
        allowedURLPatterns: [String] = [],
        javaScriptEnabled: Bool = true,
        blockPopups: Bool = false,
        persistCookies: Bool = true,
        notificationsEnabled: Bool = true,
        cameraAccessEnabled: Bool = true,
        microphoneAccessEnabled: Bool = true,
        defaultWindowSize: CGSize? = nil,
        minimumWindowSize: CGSize? = nil
    ) {
        self.id = id
        self.name = name
        self.homeURL = homeURL
        self.bundleIdentifier = bundleIdentifier
        self.userAgent = userAgent
        self.showNavigationBar = showNavigationBar
        self.windowTitleMode = windowTitleMode
        self.externalLinkBehavior = externalLinkBehavior
        self.allowedURLPatterns = allowedURLPatterns
        self.javaScriptEnabled = javaScriptEnabled
        self.blockPopups = blockPopups
        self.persistCookies = persistCookies
        self.notificationsEnabled = notificationsEnabled
        self.cameraAccessEnabled = cameraAccessEnabled
        self.microphoneAccessEnabled = microphoneAccessEnabled
        self.defaultWindowSize = defaultWindowSize
        self.minimumWindowSize = minimumWindowSize
    }

    // MARK: - Computed Properties

    /// Returns the effective bundle identifier.
    public var effectiveBundleIdentifier: String {
        bundleIdentifier ?? "com.xpycode.webapp.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    /// Returns the home domain extracted from the home URL.
    public var homeDomain: String? {
        homeURL.host
    }
}

// MARK: - Supporting Types

/// User agent mode for web requests.
public enum UserAgentMode: String, Codable, Sendable, CaseIterable {
    /// Desktop Safari user agent.
    case desktop
    /// Mobile Safari user agent.
    case mobile
    /// Custom user agent string.
    case custom

    /// Returns the user agent string for this mode.
    ///
    /// - Parameter customValue: Custom user agent string (only used for `.custom` mode).
    /// - Returns: The user agent string.
    public func userAgentString(customValue: String? = nil) -> String? {
        switch self {
        case .desktop:
            return nil // Use WebKit default (desktop Safari)
        case .mobile:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        case .custom:
            return customValue
        }
    }
}

/// How the window title should be determined.
public enum WindowTitleMode: String, Codable, Sendable, CaseIterable {
    /// Use the page's <title> element.
    case pageTitle
    /// Use the app name from configuration.
    case appName
    /// Use a combination of app name and page title.
    case combined
}

/// How to handle links that navigate outside the home domain.
public enum ExternalLinkBehavior: String, Codable, Sendable, CaseIterable {
    /// Open external links in the default system browser.
    case openInDefaultBrowser
    /// Open external links in a new tab within the app.
    case openInNewTab
    /// Block external navigation entirely.
    case block
    /// Allow navigation within the same tab.
    case allowInPlace
}

// MARK: - CGSize Conformances

extension CGSize: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

extension CGSize: @retroactive Equatable {
    public static func == (lhs: CGSize, rhs: CGSize) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension CGSize: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension CGSize: @retroactive @unchecked Sendable {}
