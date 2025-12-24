// TabWebView.swift
// WebApp - Website Wrapper Factory for macOS
// Copyright © 2024 Xpycode. All rights reserved.

import WebKit
import AppKit

/// Custom WKWebView subclass that adds "Open in New Tab" context menu options.
///
/// This subclass intercepts the context menu and adds options to open links
/// in new tabs or background tabs, similar to standard browser behavior.
@MainActor
public final class TabWebView: WKWebView {

    // MARK: - Properties

    /// Callback to open a URL in a new tab.
    public var onOpenInNewTab: ((URL, Bool) -> Void)?

    /// The URL that was right-clicked (for context menu actions).
    private var contextMenuLinkURL: URL?

    // MARK: - Context Menu

    public override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)

        // Get the link URL at the click location
        contextMenuLinkURL = nil

        // Use JavaScript to find if we clicked on a link
        let point = convert(event.locationInWindow, from: nil)
        let js = """
            (function() {
                var element = document.elementFromPoint(\(point.x), \(bounds.height - point.y));
                while (element && element.tagName !== 'A') {
                    element = element.parentElement;
                }
                return element ? element.href : null;
            })()
        """

        // We need to get the link synchronously for the menu, so we'll check
        // if there's already an "Open Link" item in the menu
        var hasLinkItem = false
        var insertIndex = 0

        for (index, item) in menu.items.enumerated() {
            let title = item.title.lowercased()
            if title.contains("open link") || title.contains("öffne link") {
                hasLinkItem = true
                insertIndex = index + 1

                // Try to get URL from the existing menu item's represented object
                if let url = item.representedObject as? URL {
                    contextMenuLinkURL = url
                }
                break
            }
        }

        // If we found a link context, add our custom items
        if hasLinkItem {
            // We'll use async evaluation but add placeholder items
            evaluateJavaScript(js) { [weak self] result, _ in
                if let urlString = result as? String, let url = URL(string: urlString) {
                    self?.contextMenuLinkURL = url
                }
            }

            // Add our menu items
            let openInNewTab = NSMenuItem(
                title: "Open Link in New Tab",
                action: #selector(openLinkInNewTab(_:)),
                keyEquivalent: ""
            )
            openInNewTab.target = self

            let openInBackgroundTab = NSMenuItem(
                title: "Open Link in Background Tab",
                action: #selector(openLinkInBackgroundTab(_:)),
                keyEquivalent: ""
            )
            openInBackgroundTab.target = self

            menu.insertItem(openInNewTab, at: insertIndex)
            menu.insertItem(openInBackgroundTab, at: insertIndex + 1)

            // Try to extract URL from clipboard or find it another way
            extractLinkURL(from: menu)
        }
    }

    /// Extracts the link URL from the context menu items.
    private func extractLinkURL(from menu: NSMenu) {
        for item in menu.items {
            // Check "Copy Link" action to get the URL
            if item.action == NSSelectorFromString("copy:") ||
               item.title.lowercased().contains("copy link") {
                // The URL might be set when the action fires
            }

            // Try to find URL in represented objects
            if let url = item.representedObject as? URL {
                contextMenuLinkURL = url
                return
            }

            // Check if there's an associated URL in the item's view
            if let submenu = item.submenu {
                extractLinkURL(from: submenu)
            }
        }
    }

    @objc private func openLinkInNewTab(_ sender: NSMenuItem) {
        // Get URL via JavaScript if we don't have it
        if let url = contextMenuLinkURL {
            onOpenInNewTab?(url, false)
        } else {
            // Fallback: try to get from pasteboard after "Copy Link"
            getClickedLinkURL { [weak self] url in
                if let url = url {
                    self?.onOpenInNewTab?(url, false)
                }
            }
        }
    }

    @objc private func openLinkInBackgroundTab(_ sender: NSMenuItem) {
        if let url = contextMenuLinkURL {
            onOpenInNewTab?(url, true)
        } else {
            getClickedLinkURL { [weak self] url in
                if let url = url {
                    self?.onOpenInNewTab?(url, true)
                }
            }
        }
    }

    /// Gets the URL of the link that was clicked using JavaScript.
    private func getClickedLinkURL(completion: @escaping (URL?) -> Void) {
        // Use the last known mouse position
        let js = """
            (function() {
                var selection = window.getSelection();
                if (selection.rangeCount > 0) {
                    var range = selection.getRangeAt(0);
                    var element = range.startContainer.parentElement;
                    while (element && element.tagName !== 'A') {
                        element = element.parentElement;
                    }
                    if (element) return element.href;
                }
                // Try to get from focused element
                var active = document.activeElement;
                if (active && active.tagName === 'A') return active.href;
                return null;
            })()
        """

        evaluateJavaScript(js) { result, _ in
            if let urlString = result as? String, let url = URL(string: urlString) {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }
}
