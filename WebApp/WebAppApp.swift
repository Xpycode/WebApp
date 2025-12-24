// WebAppApp.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import SwiftUI
import WebAppFeature

/// Main application entry point for WebApp.
///
/// This app operates in two modes:
/// - **Creator Mode**: When no configuration exists, shows the factory UI
/// - **Wrapper Mode**: When configuration exists, shows the web wrapper
@main
struct WebAppApp: App {

    /// App delegate for handling application lifecycle events.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
        }
        .commands {
            // Replace default new window command
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("New Window") {
                    NotificationCenter.default.post(name: .newWindow, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Reopen Closed Tab") {
                    NotificationCenter.default.post(name: .reopenClosedTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            // Navigation commands
            CommandGroup(after: .toolbar) {
                Button("Back") {
                    NotificationCenter.default.post(name: .navigateBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Forward") {
                    NotificationCenter.default.post(name: .navigateForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)

                Divider()

                Button("Reload Page") {
                    NotificationCenter.default.post(name: .reloadPage, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Go Home") {
                    NotificationCenter.default.post(name: .goHome, object: nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            }

            // Tab navigation commands
            CommandMenu("Tab") {
                Button("Show Next Tab") {
                    NotificationCenter.default.post(name: .nextTab, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Show Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Divider()

                // Tab selection shortcuts (1-9)
                ForEach(1..<10, id: \.self) { number in
                    Button("Go to Tab \(number)") {
                        NotificationCenter.default.post(
                            name: .selectTab,
                            object: nil,
                            userInfo: ["number": number]
                        )
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: .command)
                }
            }

            // Help commands
            CommandGroup(replacing: .help) {
                Button("WebApp Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/Xpycode/WebApp")!)
                }
            }
        }

        // Settings window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - App Delegate

/// Application delegate for handling app lifecycle and services.
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even if all windows are closed (macOS convention)
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

// MARK: - Notification Names

extension Notification.Name {
    // Tab management
    static let newTab = Notification.Name("com.xpycode.webapp.newTab")
    static let closeTab = Notification.Name("com.xpycode.webapp.closeTab")
    static let reopenClosedTab = Notification.Name("com.xpycode.webapp.reopenClosedTab")
    static let nextTab = Notification.Name("com.xpycode.webapp.nextTab")
    static let previousTab = Notification.Name("com.xpycode.webapp.previousTab")
    static let selectTab = Notification.Name("com.xpycode.webapp.selectTab")

    // Window management
    static let newWindow = Notification.Name("com.xpycode.webapp.newWindow")

    // Navigation
    static let navigateBack = Notification.Name("com.xpycode.webapp.navigateBack")
    static let navigateForward = Notification.Name("com.xpycode.webapp.navigateForward")
    static let reloadPage = Notification.Name("com.xpycode.webapp.reloadPage")
    static let goHome = Notification.Name("com.xpycode.webapp.goHome")
}
