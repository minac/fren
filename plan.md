# Fren — Instant Translation Overlay for macOS

## What is this?

A tiny macOS app. Press `⌥ + T` from anywhere, a centered overlay appears, type text, get a translation. That's it.

## Why?

Existing tools require too many clicks. This is for someone learning French who needs instant, zero-friction translation dozens of times a day.

## User Flow

1. Press `⌥ + T` from anywhere.
2. A floating overlay appears centered on screen: one text input, auto-focused.
3. Type or paste text, press `Enter`.
4. Result appears below the input.
5. Press `⌘ + C` or click result to copy to clipboard.
6. Press `⌥ + S` to swap — keeps the current input text, switches source/target languages, re-translates.
7. Press `Escape` to dismiss. Done.

## Behaviour

### Translation Logic

- **Default mode:** Auto-detect source language via DeepL. If detected as French → translate to English. If English → translate to French.
- **Swap override (`⌥ + S`):** Forces the opposite direction. Use case: DeepL auto-detects wrong, or you typed English but want to see how it sounds in French. Keeps the input text, swaps the pair, re-sends.
- **Language pair:** Hardcoded to FR ↔ EN. Configurable later if needed, not now.

### Window Behaviour

- Floating panel (NSPanel, `.nonActivating` style) — appears above all windows.
- Centered on the screen where the cursor currently is (multi-monitor friendly).
- No title bar, no chrome. Rounded corners, subtle shadow, translucent background (vibrancy).
- Dismisses on `Escape` or click outside.
- No Dock icon. No menu bar icon. The app is invisible until summoned.

## Technical Spec

### Stack

- **Language:** Swift
- **UI:** SwiftUI hosted in an NSPanel
- **App type:** macOS background app (LSUIElement = true, no Dock icon, no menu bar icon)
- **Min target:** macOS 14 (Sonoma)
- **Translation API:** DeepL API Free

### Project Structure

```
Fren/
├── FrenApp.swift              # @main, app lifecycle, LSUIElement
├── OverlayPanel.swift         # NSPanel setup (floating, no chrome)
├── TranslationView.swift      # SwiftUI: input + result + swap
├── DeepLService.swift         # Single async function
├── HotkeyManager.swift        # Global hotkey via CGEvent tap
└── Config.swift               # API key (Keychain), language pair
```

### DeepL API

- **Endpoint:** `POST https://api-free.deepl.com/v2/translate`
- **Body:**
  ```json
  {
    "text": ["bonjour"],
    "target_lang": "EN"
  }
  ```
  Omit `source_lang` for auto-detect. Use `detected_source_language` in response to show direction label.
- When swap is triggered, explicitly set `source_lang` and `target_lang` to override auto-detect.
- **API key:** Stored in macOS Keychain.

### UI Spec

- **Overlay size:** ~480pt wide, height fits content (input + result + direction label).
- **Input:** Single `TextField`, placeholder "Type to translate…", auto-focused.
- **Direction label:** Small, muted text between input and result: "FR → EN" (updates on swap).
- **Result:** Translated text, selectable. Clicking copies to clipboard (brief "Copied!" flash).
- **Swap indicator:** Show `⌥S to swap` hint near the direction label.
- **Loading:** Inline "…" or subtle opacity pulse. No spinner.
- **First launch:** If no API key in Keychain, show a single-field prompt: "Paste your DeepL API key" with a link to https://www.deepl.com/pro#developer. Store and never ask again.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌥ + T` | Toggle overlay (global, works from any app) |
| `Enter` | Translate |
| `⌥ + S` | Swap languages, keep input, re-translate |
| `⌘ + C` | Copy result (when result is focused/shown) |
| `Escape` | Dismiss overlay |

### Non-Functional

- **No history.** No saved translations. No bookmarks.
- **No analytics.** No telemetry. No logging.
- **Launch at login:** Yes, by default (toggle via right-click if menu bar icon is ever added).
- **App size:** Should be trivially small. No embedded frameworks beyond Foundation/SwiftUI.

## Out of Scope

- Menu bar icon
- Translation history
- Multiple language pairs at once
- Text-to-speech
- Offline mode
- Settings UI beyond the initial API key prompt
- iOS version
- Anything that makes this more than one text field and one result

## Setup

1. Get a free DeepL API key: https://www.deepl.com/pro#developer
2. Open Fren. Paste API key on first launch.
3. Press `⌥ + T` anywhere. Type. Enter. Done.

## Definition of Done

- [ ] `⌥ + T` opens overlay from any app
- [ ] Input field is auto-focused
- [ ] Enter translates, result appears with direction label
- [ ] `⌥ + S` swaps languages and re-translates with same input
- [ ] Click result copies to clipboard
- [ ] Escape dismisses
- [ ] No Dock icon, no menu bar icon
- [ ] API key stored in Keychain, prompted on first launch
- [ ] Builds and runs from Xcode on macOS 14+
