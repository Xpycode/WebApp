// swift-tools-version: 6.1
// WebApp - Website Wrapper Factory for macOS
// https://github.com/Xpycode/WebApp

import PackageDescription

let package = Package(
    name: "WebAppPackage",
    platforms: [.macOS(.v15)],
    products: [
        // Main feature library containing all app functionality
        .library(
            name: "WebAppFeature",
            targets: ["WebAppFeature"]
        ),
    ],
    targets: [
        // MARK: - Core Models & Configuration
        // Shared data models, configuration types, and utilities
        .target(
            name: "WebAppCore",
            dependencies: [],
            path: "Sources/WebAppCore"
        ),

        // MARK: - WebView Engine
        // WKWebView wrapper, tab management, navigation handling
        .target(
            name: "WebAppEngine",
            dependencies: ["WebAppCore"],
            path: "Sources/WebAppEngine"
        ),

        // MARK: - Main Feature Module
        // UI components for both Creator and Wrapper modes
        .target(
            name: "WebAppFeature",
            dependencies: [
                "WebAppCore",
                "WebAppEngine"
            ],
            path: "Sources/WebAppFeature"
        ),

        // MARK: - Tests
        .testTarget(
            name: "WebAppCoreTests",
            dependencies: ["WebAppCore"],
            path: "Tests/WebAppCoreTests"
        ),
        .testTarget(
            name: "WebAppEngineTests",
            dependencies: ["WebAppEngine"],
            path: "Tests/WebAppEngineTests"
        ),
        .testTarget(
            name: "WebAppFeatureTests",
            dependencies: ["WebAppFeature"],
            path: "Tests/WebAppFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
