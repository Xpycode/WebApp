// Exports.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

/// WebAppFeature Module
///
/// This is the main feature module for the WebApp application,
/// containing all user-facing views and UI components.
///
/// ## Overview
///
/// The WebAppFeature module provides two main experiences:
///
/// - **Creator Mode**: UI for creating new website wrapper apps.
/// - **Wrapper Mode**: UI for browsing the configured website.
///
/// ## Key Views
///
/// - ``ContentView``: The root view that switches between modes.
/// - ``CreatorView``: The factory app UI for creating web apps.
/// - ``WrapperView``: The web browser UI for wrapper apps.
///
/// ## Usage
///
/// ```swift
/// import SwiftUI
/// import WebAppFeature
///
/// @main
/// struct WebAppApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```

// Re-export dependent modules
@_exported import WebAppCore
@_exported import WebAppEngine
