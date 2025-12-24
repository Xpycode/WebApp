// Exports.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

/// WebAppEngine Module
///
/// This module provides the WebKit-based browsing engine for WebApp,
/// including tab management, navigation, and web view handling.
///
/// ## Overview
///
/// The WebAppEngine module contains all the components needed to render
/// websites and manage browser-like functionality within the app.
///
/// ## Key Types
///
/// - ``WebTab``: Represents a single browser tab with its web view.
/// - ``TabManager``: Manages a collection of tabs for a window.
///
/// ## Usage
///
/// ```swift
/// import WebAppEngine
/// import WebAppCore
///
/// // Create a configuration
/// let config = WebAppConfiguration(
///     name: "YouTube",
///     homeURL: URL(string: "https://youtube.com")!
/// )
///
/// // Create a tab manager
/// let tabManager = TabManager(configuration: config)
///
/// // Create new tabs
/// tabManager.createTab(with: URL(string: "https://youtube.com/feed/subscriptions")!)
/// tabManager.createTab(inBackground: true)
/// ```

// Re-export WebAppCore for convenience
@_exported import WebAppCore
