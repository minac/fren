# Project Log

## 2026-04-06 — Add structured logging, project-log, conventions alignment

- Added `AppLogger.swift` — structured JSONL logger (OSLog + `logs/app.jsonl`) per global conventions
- Added log calls to app lifecycle (`FrenApp.swift`) and translation API (`DeepLService.swift`)
- Added `logs/` to `.gitignore`
- Created `project-log.md`
- Updated `CLAUDE.md` with logging notes

## 2026-04-06 — Fix event monitor leak, task cancellation, dead code (PR #3)

- Fixed NSEvent monitor leak on every ⌥+T (stored + removed on dismiss)
- Stored translation Task for cancellation on overlay dismiss
- Handled API key save failure with user-facing alert
- Removed dead `Config.sourceLang`/`Config.targetLang`, unused variable, force-unwrap
- Merged duplicate `.onAppear` blocks
- Removed 6 zero-value tests

## 2026-04-06 — Implement plan spec (PR #1)

- Initial implementation of Fren macOS translation overlay
- DeepL API integration with auto-detect and swap
- Global hotkey (⌥+T) via CGEvent tap with Carbon fallback
- Floating NSPanel with SwiftUI, Keychain API key storage
- Configurable language support via FREN_LANGUAGES env var
- 29 unit tests covering Config, DeepL request/response, translation logic
