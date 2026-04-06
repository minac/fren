# Fren

Instant French-English translation overlay for macOS. Press `⌥T` from anywhere, type, get a translation.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+
- A free DeepL API key

## Getting a DeepL API Key

1. Go to [https://www.deepl.com/pro#developer](https://www.deepl.com/pro#developer)
2. Click **Sign up for free**
3. Create an account (email + password, no credit card required for the Free plan)
4. After signing in, go to your [Account Summary](https://www.deepl.com/account/summary)
5. Scroll to **Authentication Key for DeepL API** — copy the key
6. The key looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:fx` (the `:fx` suffix indicates the free tier)

## Build & Run

```bash
git clone https://github.com/minac/fren.git
cd fren

# Build and launch
./run.sh run

# Or open in Xcode
open Fren.xcodeproj
```

On first launch, Fren will prompt you to paste your DeepL API key. The key is stored securely in the macOS Keychain and never asked for again.

### Accessibility Permission

Fren uses a global hotkey (`⌥T`) via a CGEvent tap. macOS will prompt you to grant **Accessibility** permission the first time:

> System Settings → Privacy & Security → Accessibility → enable Fren

## Usage

| Shortcut | Action |
|----------|--------|
| `⌥T` | Show/hide the translation overlay |
| `Enter` | Translate the input text |
| `⌥S` | Swap language direction and re-translate |
| `⌘C` | Copy the translated result |
| `Escape` | Dismiss the overlay |

### Translation Logic

- **Auto-detect mode (default):** Type in any language. If French is detected, translates to English. If English is detected, translates to French.
- **Swap (`⌥S`):** Reverses the current translation direction. Keeps your input text, swaps source/target, and re-translates. Useful when auto-detect guesses wrong or you want to check the reverse.

### Behaviour

- The overlay appears centered on whichever screen your cursor is on (multi-monitor friendly)
- No Dock icon, no menu bar icon — the app is invisible until summoned
- Clicking the translated result copies it to your clipboard
- Click outside the overlay or press `Escape` to dismiss

## Project Structure

```
Fren/
├── FrenApp.swift          # @main, AppDelegate, app lifecycle (LSUIElement)
├── OverlayPanel.swift     # NSPanel — floating, borderless, vibrancy
├── TranslationView.swift  # SwiftUI — input, result, direction label, swap
├── DeepLService.swift     # Async DeepL API client
├── HotkeyManager.swift    # Global ⌥T hotkey via CGEvent tap + Carbon fallback
├── Config.swift           # Keychain API key storage, language routing
├── AppLogger.swift        # Structured JSONL logger (OSLog + logs/app.jsonl)
run.sh                     # Build, test, package, sign, release
```

## Running Tests

```bash
./run.sh test

# Or in Xcode: ⌘U
```

### What the Tests Cover

- **DeepL API response parsing** — valid JSON, empty translations, malformed JSON
- **DeepL error handling** — missing API key, HTTP error codes, network errors
- **DeepL request construction** — correct URL, headers, body with/without source language
- **Config language routing** — primary/secondary targeting, unknown language fallback
- **Translation auto-detect logic** — detected language routes to correct target

## License

MIT
