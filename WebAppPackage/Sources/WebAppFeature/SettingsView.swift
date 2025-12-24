// SettingsView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebKit
import WebAppCore

/// Settings view for the WebApp application.
///
/// Provides configuration options for app behavior, appearance, and privacy.
public struct SettingsView: View {

    // MARK: - Properties

    @AppStorage("defaultUserAgent") private var defaultUserAgent: String = "desktop"
    @AppStorage("blockPopups") private var blockPopups: Bool = false
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true

    @State private var showingClearBrowsingDataAlert = false
    @State private var showingClearCookiesAlert = false
    @State private var clearInProgress = false

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
                    showingClearBrowsingDataAlert = true
                }
                .disabled(clearInProgress)

                Button("Clear Cookies...") {
                    showingClearCookiesAlert = true
                }
                .disabled(clearInProgress)

                if clearInProgress {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Clearing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        .alert("Clear Browsing Data", isPresented: $showingClearBrowsingDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearBrowsingData()
            }
        } message: {
            Text("This will clear all browsing history, cached images and files, and other browsing data. This action cannot be undone.")
        }
        .alert("Clear Cookies", isPresented: $showingClearCookiesAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearCookies()
            }
        } message: {
            Text("This will clear all cookies and website data. You will be signed out of all websites. This action cannot be undone.")
        }
    }

    // MARK: - Data Clearing Actions

    private func clearBrowsingData() {
        clearInProgress = true
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ]

        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                Task { @MainActor in
                    clearInProgress = false
                }
            }
        }
    }

    private func clearCookies() {
        clearInProgress = true
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeCookies
        ]

        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                Task { @MainActor in
                    clearInProgress = false
                }
            }
        }
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
