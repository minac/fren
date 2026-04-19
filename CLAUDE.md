# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
./run.sh build            # Debug build
./run.sh build release    # Release build
./run.sh test             # Run all tests
./run.sh run              # Build debug and launch
./run.sh package          # Build release .app to build/ and install to /Applications/
./run.sh release <ver>    # Full pipeline: build → sign → dmg → notarize
```

Single test class/method (no `run.sh` shortcut):
```bash
xcodebuild test -project Fren.xcodeproj -scheme Fren -destination 'platform=macOS' -only-testing:FrenTests/ConfigTests
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

## Logging

Structured JSONL to `logs/app.jsonl` (gitignored) via `AppLogger.swift`. Dual output: OSLog (Console.app) + JSONL file.

Usage: `log.info("msg", ctx: ["key": "value"])`. Levels: `debug`, `info`, `warn`, `error`.

Query: `~/.claude/scripts/query-logs.sh`

## Project Notes

- **No XcodeGen** — `.pbxproj` is edited directly (unlike other Swift projects). If XcodeGen is added later, switch to `project.yml` as source of truth.
- **No SPM** — pure Xcode project. Build/test via `xcodebuild`, not `swift build/test`.
