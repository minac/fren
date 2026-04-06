# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
# Build (Debug)
xcodebuild build -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS' -configuration Debug

# Build (Release)
xcodebuild build -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS' -configuration Release

# Run all tests
xcodebuild test -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS'

# Run a single test class
xcodebuild test -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS' -only-testing:FrenTests/ConfigTests

# Run a single test method
xcodebuild test -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS' -only-testing:FrenTests/ConfigTests/testDefaultLanguagePair

# Install to /Applications
cp -R "$(xcodebuild -project Fren.xcodeproj -scheme Fren -configuration Release -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/Fren.app" /Applications/Fren.app
```

## Architecture

Fren is a macOS background app (LSUIElement) — no Dock icon, no menu bar. SwiftUI views are hosted inside an `NSPanel` for floating overlay behavior.

**Key design decisions:**
- **HotkeyManager** uses CGEvent tap (preferred, suppresses keystroke) with Carbon `RegisterEventHotKey` fallback. The fallback activates when Accessibility permission isn't granted for the event tap.
- **OverlayPanel** must call `NSApp.activate(ignoringOtherApps: true)` before `makeKeyAndOrderFront` to ensure the SwiftUI `@FocusState` text field gets keyboard focus.
- **TranslationView** uses `NSEvent.addLocalMonitorForEvents` (not an NSView subclass) to intercept `⌥+S` before it reaches the text field — prevents the system from inserting the `ß` character.
- **Config.targetLang(forDetected:)** handles language routing: detected primary lang -> second supported lang, anything else -> primary lang. Supported languages are read from `FREN_LANGUAGES` env var (comma-separated, defaults to `EN,FR`).
- **DeepL translation** uses a two-pass approach: first call auto-detects with target=primary lang. If detected source IS the primary lang, a second call re-translates to the second supported language.
- App sandbox is **disabled** (required for CGEvent tap / accessibility).
- API key is stored in macOS Keychain under service `com.fren.app`, account `deepl-api-key`.

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `FREN_LANGUAGES` | Comma-separated language codes (first is primary) | `EN,FR` |

Set in Xcode scheme for development. For standalone use: `FREN_LANGUAGES="EN,FR" open /Applications/Fren.app`
