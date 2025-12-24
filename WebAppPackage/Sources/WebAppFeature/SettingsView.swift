// SettingsView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebAppCore

/// Settings view for the WebApp application.
///
/// Provides configuration options for app behavior, appearance, and privacy.
public struct SettingsView: View {

    // MARK: - Properties

    @AppStorage("defaultUserAgent") private var defaultUserAgent: String = "desktop"
    @AppStorage("blockPopups") private var blockPopups: Bool = false
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true

    // MARK: - Body

    public var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            privacySettings
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }

            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section {
                Picker("Default User Agent", selection: $defaultUserAgent) {
                    Text("Desktop Safari").tag("desktop")
                    Text("Mobile Safari").tag("mobile")
                }
                .pickerStyle(.menu)

                Toggle("Block Pop-up Windows", isOn: $blockPopups)
            } header: {
                Text("Browsing")
            }

            Section {
                Toggle("Enable Web Notifications", isOn: $enableNotifications)
            } header: {
                Text("Notifications")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Privacy Settings

    private var privacySettings: some View {
        Form {
            Section {
                Button("Clear Browsing Data...") {
                    // TODO: Implement clear browsing data
                }

                Button("Clear Cookies...") {
                    // TODO: Implement clear cookies
                }
            } header: {
                Text("Privacy")
            }

            Section {
                Text("Each web app maintains its own isolated cookies and browsing data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Cookie Isolation")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About View

    private var aboutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("WebApp")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("A website wrapper factory for macOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com/Xpycode/WebApp")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Initialization

    public init() {}
}

// MARK: - Preview

#Preview {
    SettingsView()
}
