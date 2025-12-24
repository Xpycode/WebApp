// CreatorView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebAppCore

/// The main view for the WebApp Creator - the factory app for creating web apps.
///
/// This view provides the UI for:
/// - Configuring new web apps (name, URL, settings)
/// - Managing saved configurations
/// - Generating standalone wrapper apps
public struct CreatorView: View {

    // MARK: - Properties

    @State private var appName: String = ""
    @State private var urlString: String = ""
    @State private var showNavigationBar: Bool = false
    @State private var userAgentMode: UserAgentMode = .desktop
    @State private var externalLinkBehavior: ExternalLinkBehavior = .openInDefaultBrowser

    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - Body

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            configurationForm
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WebApp Creator")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            List {
                Section("Quick Start") {
                    Label("New Web App", systemImage: "plus.circle")
                        .tag("new")
                }

                Section("Saved Apps") {
                    Text("No saved apps yet")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200)
    }

    // MARK: - Configuration Form

    private var configurationForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                // Basic Settings
                basicSettingsSection

                Divider()

                // Appearance Settings
                appearanceSection

                Divider()

                // Behavior Settings
                behaviorSection

                Divider()

                // Actions
                actionsSection
            }
            .padding(32)
        }
    }

    // MARK: - Form Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create New Web App")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configure your website wrapper and generate a standalone macOS app.")
                .foregroundStyle(.secondary)
        }
    }

    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Settings")
                .font(.headline)

            LabeledContent("App Name") {
                TextField("e.g., YouTube, Reddit", text: $appName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
            }

            LabeledContent("Website URL") {
                TextField("https://youtube.com", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 400)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)

            Toggle("Show Navigation Bar", isOn: $showNavigationBar)

            LabeledContent("User Agent") {
                Picker("", selection: $userAgentMode) {
                    Text("Desktop Safari").tag(UserAgentMode.desktop)
                    Text("Mobile Safari").tag(UserAgentMode.mobile)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)
            }
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Behavior")
                .font(.headline)

            LabeledContent("External Links") {
                Picker("", selection: $externalLinkBehavior) {
                    Text("Open in Browser").tag(ExternalLinkBehavior.openInDefaultBrowser)
                    Text("Open in New Tab").tag(ExternalLinkBehavior.openInNewTab)
                    Text("Block").tag(ExternalLinkBehavior.block)
                    Text("Allow In-Place").tag(ExternalLinkBehavior.allowInPlace)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 16) {
            Button("Preview") {
                // TODO: Implement preview
            }
            .buttonStyle(.bordered)

            Button("Create App...") {
                createApp()
            }
            .buttonStyle(.borderedProminent)
            .disabled(appName.isEmpty || urlString.isEmpty)
        }
        .padding(.top)
    }

    // MARK: - Actions

    private func createApp() {
        guard let url = URL(string: urlString), url.scheme != nil else {
            errorMessage = "Please enter a valid URL including the scheme (https://)"
            showingError = true
            return
        }

        let configuration = WebAppConfiguration(
            name: appName,
            homeURL: url,
            userAgent: userAgentMode,
            showNavigationBar: showNavigationBar,
            externalLinkBehavior: externalLinkBehavior
        )

        // TODO: Implement app generation
        print("Would create app with config: \(configuration)")
    }

    // MARK: - Initialization

    public init() {}
}

// MARK: - Preview

#Preview {
    CreatorView()
}
