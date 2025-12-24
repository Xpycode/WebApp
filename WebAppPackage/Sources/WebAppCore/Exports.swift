// Exports.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

/// WebAppCore Module
///
/// This module contains the core data models and configuration types
/// used throughout the WebApp application.
///
/// ## Overview
///
/// The WebApp application operates in two modes:
///
/// - **Creator Mode**: The main factory application where users can
///   configure and generate new website wrapper apps.
///
/// - **Wrapper Mode**: Generated applications that wrap a specific
///   website with a native macOS experience.
///
/// ## Key Types
///
/// - ``WebAppConfiguration``: The main configuration model for web apps.
/// - ``AppMode``: Enum representing the current operating mode.
/// - ``UserAgentMode``: Options for user agent configuration.
/// - ``ExternalLinkBehavior``: How to handle external links.
/// - ``WindowTitleMode``: How to determine window titles.
///
/// ## Usage
///
/// ```swift
/// import WebAppCore
///
/// // Detect current mode
/// let mode = AppMode.detect()
///
/// switch mode {
/// case .creator:
///     // Show creator UI
/// case .wrapper(let config):
///     // Show web wrapper with configuration
/// }
/// ```

// All public types are automatically exported from this module.
// This file exists primarily for documentation purposes.
