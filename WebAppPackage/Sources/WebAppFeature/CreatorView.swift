// CreatorView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebKit
import WebAppCore
import WebAppEngine

/// The main view for the WebApp Creator - the factory app for creating web apps.
///
/// This view provides the UI for:
/// - Configuring new web apps (name, URL, settings)
/// - Previewing the website before creating
/// - Generating standalone wrapper apps
public struct CreatorView: View {

    // MARK: - Properties

    @State private var appName: String = ""
    @State private var urlString: String = "https://"
    @State private var showNavigationBar: Bool = false
    @State private var userAgentMode: UserAgentMode = .desktop
    @State private var externalLinkBehavior: ExternalLinkBehavior = .openInDefaultBrowser
    @State private var javaScriptEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var cameraEnabled: Bool = true
    @State private var microphoneEnabled: Bool = true

    @State private var showingPreview: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingSavePanel: Bool = false
    @State private var isCreatingApp: Bool = false

    @State private var previewConfiguration: WebAppConfiguration?

    // MARK: - Body

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if showingPreview, let config = previewConfiguration {
                previewView(configuration: config)
            } else {
                configurationForm
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "globe.badge.chevron.backward")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("WebApp")
                    .font(.headline)
            }
            .padding()

            Divider()

            List {
                Section("Create") {
                    Button {
                        showingPreview = false
                        resetForm()
                    } label: {
                        Label("New Web App", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }

                Section("Templates") {
                    templateButton(name: "YouTube", url: "https://youtube.com", icon: "play.rectangle.fill")
                    templateButton(name: "Reddit", url: "https://reddit.com", icon: "bubble.left.and.bubble.right.fill")
                    templateButton(name: "Twitter/X", url: "https://x.com", icon: "at.circle.fill")
                    templateButton(name: "GitHub", url: "https://github.com", icon: "chevron.left.forwardslash.chevron.right")
                }

                Section("Info") {
                    Link(destination: URL(string: "https://github.com/Xpycode/WebApp")!) {
                        Label("Documentation", systemImage: "book")
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, idealWidth: 220)
    }

    private func templateButton(name: String, url: String, icon: String) -> some View {
        Button {
            appName = name
            urlString = url
            showingPreview = false
        } label: {
            Label(name, systemImage: icon)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Configuration Form

    private var configurationForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                Divider()
                basicSettingsSection
                Divider()
                appearanceSection
                Divider()
                permissionsSection
                Divider()
                behaviorSection
                Divider()
                actionsSection
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview View

    private func previewView(configuration: WebAppConfiguration) -> some View {
        VStack(spacing: 0) {
            // Preview header
            HStack {
                Button {
                    showingPreview = false
                } label: {
                    Label("Back to Editor", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Preview: \(configuration.name)")
                    .font(.headline)

                Spacer()

                Button("Create App...") {
                    createApp()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Web preview
            WrapperView(configuration: configuration)
        }
    }

    // MARK: - Form Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                iconPreview
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create New Web App")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Turn any website into a standalone macOS application")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var iconPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            if let firstChar = appName.first {
                Text(String(firstChar).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
        }
    }

    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Basic Settings", icon: "gear")

            FormField(label: "App Name", description: "The name displayed in Dock and menu bar") {
                TextField("e.g., YouTube, Reddit", text: $appName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 350)
            }

            FormField(label: "Website URL", description: "The main page to load when the app starts") {
                HStack {
                    TextField("https://youtube.com", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)

                    Button {
                        if let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")
                    .disabled(!isValidURL)
                }
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Appearance", icon: "paintbrush")

            FormField(label: "Navigation Bar", description: "Show URL bar and navigation controls") {
                Toggle("Show Navigation Bar", isOn: $showNavigationBar)
                    .toggleStyle(.switch)
            }

            FormField(label: "User Agent", description: "How the app identifies itself to websites") {
                Picker("", selection: $userAgentMode) {
                    Text("Desktop Safari").tag(UserAgentMode.desktop)
                    Text("Mobile Safari").tag(UserAgentMode.mobile)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Permissions", icon: "hand.raised")

            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("JavaScript", isOn: $javaScriptEnabled)
                    Toggle("Notifications", isOn: $notificationsEnabled)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Camera", isOn: $cameraEnabled)
                    Toggle("Microphone", isOn: $microphoneEnabled)
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Behavior", icon: "arrow.triangle.branch")

            FormField(label: "External Links", description: "How to handle links outside the main domain") {
                Picker("", selection: $externalLinkBehavior) {
                    Text("Open in Default Browser").tag(ExternalLinkBehavior.openInDefaultBrowser)
                    Text("Open in New Tab").tag(ExternalLinkBehavior.openInNewTab)
                    Text("Block").tag(ExternalLinkBehavior.block)
                    Text("Allow In-Place").tag(ExternalLinkBehavior.allowInPlace)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            }
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 16) {
            Button("Preview") {
                startPreview()
            }
            .buttonStyle(.bordered)
            .disabled(!canCreate)

            Button("Create App...") {
                createApp()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canCreate || isCreatingApp)

            if isCreatingApp {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private var isValidURL: Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    private var canCreate: Bool {
        !appName.trimmingCharacters(in: .whitespaces).isEmpty && isValidURL
    }

    private func resetForm() {
        appName = ""
        urlString = "https://"
        showNavigationBar = false
        userAgentMode = .desktop
        externalLinkBehavior = .openInDefaultBrowser
    }

    // MARK: - Actions

    private func startPreview() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Please enter a valid URL"
            showingError = true
            return
        }

        previewConfiguration = WebAppConfiguration(
            name: appName.isEmpty ? "Preview" : appName,
            homeURL: url,
            userAgent: userAgentMode,
            showNavigationBar: showNavigationBar,
            externalLinkBehavior: externalLinkBehavior,
            javaScriptEnabled: javaScriptEnabled,
            notificationsEnabled: notificationsEnabled,
            cameraAccessEnabled: cameraEnabled,
            microphoneAccessEnabled: microphoneEnabled
        )
        showingPreview = true
    }

    private func createApp() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Please enter a valid URL including the scheme (https://)"
            showingError = true
            return
        }

        let configuration = WebAppConfiguration(
            name: appName,
            homeURL: url,
            userAgent: userAgentMode,
            showNavigationBar: showNavigationBar,
            externalLinkBehavior: externalLinkBehavior,
            javaScriptEnabled: javaScriptEnabled,
            notificationsEnabled: notificationsEnabled,
            cameraAccessEnabled: cameraEnabled,
            microphoneAccessEnabled: microphoneEnabled
        )

        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.application]
        savePanel.nameFieldStringValue = "\(appName).app"
        savePanel.title = "Save Web App"
        savePanel.message = "Choose where to save your new web app"

        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                Task {
                    await generateApp(configuration: configuration, at: saveURL)
                }
            }
        }
    }

    @MainActor
    private func generateApp(configuration: WebAppConfiguration, at url: URL) async {
        isCreatingApp = true
        defer { isCreatingApp = false }

        do {
            try await AppGenerator.shared.generateApp(
                configuration: configuration,
                destination: url
            )

            // Open the containing folder
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        } catch {
            errorMessage = "Failed to create app: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Initialization

    public init() {}
}

// MARK: - Form Field Helper

struct FormField<Content: View>: View {
    let label: String
    let description: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .fontWeight(.medium)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 180, alignment: .leading)

                content()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreatorView()
}
