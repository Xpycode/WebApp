# WebApp - Website Wrapper Factory for macOS

A modern macOS application that creates standalone website wrapper apps. Turn any website into a native-feeling macOS app with tabs, multiple windows, and full WebKit functionality.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![Universal Binary](https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-green)

## Features

- **Website Wrapping**: Create standalone apps for any website (YouTube, Reddit, etc.)
- **Modern WebKit**: Full WKWebView with JavaScript, media, and modern web standards
- **Tab Support**: Full tabbed browsing within each web app
- **Background Tabs**: Open links in background tabs via context menu
- **Multiple Windows**: Native macOS multi-window support
- **Web Notifications**: Support for web push notifications
- **Privacy**: Cookie isolation between different web apps
- **Native Feel**: No visible URL bar for app-like experience

## Project Architecture

```
WebApp/
├── WebApp.xcworkspace/           # Open this in Xcode
├── WebApp.xcodeproj/             # App shell project
├── WebApp/                       # App target
│   ├── WebAppApp.swift              # App entry point
│   └── Assets.xcassets/             # App icons and colors
├── WebAppPackage/                # 🚀 Primary development area
│   ├── Package.swift                # SPM package configuration
│   ├── Sources/
│   │   ├── WebAppCore/              # Core models & configuration
│   │   ├── WebAppEngine/            # WebKit engine & tab management
│   │   └── WebAppFeature/           # UI components
│   └── Tests/                       # Unit tests
├── Config/                       # Build configuration
│   ├── WebApp.entitlements          # App sandbox settings
│   └── *.xcconfig                   # Build settings
└── Documentation/                # Project documentation
```

## Modules

### WebAppCore

Core data models and configuration types:

- **`WebAppConfiguration`**: Complete configuration for a web app instance
- **`AppMode`**: Detects Creator vs Wrapper mode based on bundle contents
- **`UserAgentMode`**: Desktop/Mobile/Custom user agent options
- **`ExternalLinkBehavior`**: How to handle external links
- **`WindowTitleMode`**: Window title display options

### WebAppEngine

WebKit-based browsing engine:

- **`WebTab`**: Single browser tab with WKWebView and state observations
- **`TabManager`**: Manages tab collection with creation, navigation, and ordering

### WebAppFeature

User interface components:

- **`ContentView`**: Root view switching between Creator and Wrapper modes
- **`CreatorView`**: Factory UI for creating new web apps
- **`WrapperView`**: Browser UI for wrapped websites
- **`TabBarView`**: Tab bar component with drag-and-drop support

## How It Works

### Dual-Mode Architecture

WebApp operates in two modes:

1. **Creator Mode**: When no configuration file exists in the bundle
   - Shows the factory UI for creating new web apps
   - Configure app name, URL, behavior settings
   - Generate standalone wrapper apps

2. **Wrapper Mode**: When `WebAppConfig.plist` exists in the bundle
   - Loads configuration from the embedded plist
   - Displays the web wrapper with tabs and navigation
   - Acts as a standalone website app

### App Generation

When creating a new web app:

1. User configures the app in Creator mode
2. WebApp duplicates itself to the chosen location
3. Configuration is embedded as `WebAppConfig.plist`
4. The new app launches in Wrapper mode

## Building

### Requirements

- macOS 15.0+ (Sequoia)
- Xcode 16.0+
- Swift 6.0+

### Build Commands

```bash
# Open in Xcode
open WebApp.xcworkspace

# Build from command line
xcodebuild -workspace WebApp.xcworkspace -scheme WebApp build

# Run tests
xcodebuild -workspace WebApp.xcworkspace -scheme WebApp test
```

## Configuration Options

### WebAppConfiguration

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Display name of the app |
| `homeURL` | `URL` | Primary URL to load |
| `bundleIdentifier` | `String?` | Custom bundle ID |
| `userAgent` | `UserAgentMode` | Desktop/Mobile/Custom |
| `showNavigationBar` | `Bool` | Show URL bar and controls |
| `windowTitleMode` | `WindowTitleMode` | How to set window title |
| `externalLinkBehavior` | `ExternalLinkBehavior` | Handle external links |
| `javaScriptEnabled` | `Bool` | Enable JavaScript |
| `persistCookies` | `Bool` | Remember cookies |
| `notificationsEnabled` | `Bool` | Allow web notifications |
| `cameraAccessEnabled` | `Bool` | Allow camera access |
| `microphoneAccessEnabled` | `Bool` | Allow microphone access |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘T | New Tab |
| ⌘W | Close Tab |
| ⌘⇧T | Reopen Closed Tab |
| ⌃Tab | Next Tab |
| ⌃⇧Tab | Previous Tab |
| ⌘1-9 | Go to Tab (9 = last) |
| ⌘N | New Window |
| ⌘R | Reload |
| ⌘[ | Back |
| ⌘] | Forward |
| ⌘⇧H | Go Home |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `xcodebuild test`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Credits

Built with ❤️ using SwiftUI and WebKit.

---

**WebApp** - Turn any website into a native macOS experience.
