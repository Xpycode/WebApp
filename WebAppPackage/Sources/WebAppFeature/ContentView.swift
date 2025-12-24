// ContentView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebAppCore
import WebAppEngine

/// The main content view that switches between Creator and Wrapper modes.
///
/// This view detects the app mode on launch and presents either:
/// - The Creator UI for making new web apps
/// - The Wrapper UI for browsing the configured website
public struct ContentView: View {
    /// The detected app mode.
    @State private var appMode: AppMode

    public init() {
        self._appMode = State(initialValue: AppMode.detect())
    }

    public var body: some View {
        Group {
            switch appMode {
            case .creator:
                CreatorView()

            case .wrapper(let configuration):
                WrapperView(configuration: configuration)
            }
        }
    }
}

// MARK: - Preview

#Preview("Creator Mode") {
    ContentView()
}
