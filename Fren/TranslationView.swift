import SwiftUI
import AppKit

struct TranslationView: View {
    @State private var inputText = ""
    @State private var resultText = ""
    @State private var directionLabel = ""
    @State private var isLoading = false
    @State private var copiedFlash = false
    @State private var errorMessage = ""
    @State private var lastSourceLang = "FR"
    @State private var lastTargetLang = "EN"
    @FocusState private var inputFocused: Bool

    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Type to translate…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .focused($inputFocused)
                .onSubmit {
                    translate()
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !directionLabel.isEmpty || isLoading {
                HStack {
                    Text(directionLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("⌥S to swap")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            if isLoading {
                Text("…")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            } else if !resultText.isEmpty {
                ZStack(alignment: .topTrailing) {
                    Text(resultText)
                        .font(.system(size: 18))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            copyResult()
                        }

                    if copiedFlash {
                        Text("Copied!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                            .transition(.opacity)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 480)
        .onAppear {
            inputFocused = true
        }
        .onExitCommand {
            onDismiss()
        }
        .background(
            SwapKeyHandler(onSwap: swapAndTranslate, onCopy: copyResult)
        )
    }

    private func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = ""

        Task {
            do {
                // First pass: auto-detect, target EN
                let result = try await DeepLService.translate(
                    text: text,
                    targetLang: "EN"
                )

                let detected = result.detectedSourceLang.prefix(2).uppercased()

                if detected == "EN" {
                    // Source is English, re-translate to French
                    let frResult = try await DeepLService.translate(
                        text: text,
                        sourceLang: "EN",
                        targetLang: "FR"
                    )
                    await MainActor.run {
                        resultText = frResult.translatedText
                        lastSourceLang = "EN"
                        lastTargetLang = "FR"
                        directionLabel = "EN → FR"
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        resultText = result.translatedText
                        lastSourceLang = String(detected)
                        lastTargetLang = "EN"
                        directionLabel = "\(detected) → EN"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func swapAndTranslate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = ""

        // Reverse the current direction
        let newSource = lastTargetLang
        let newTarget = lastSourceLang

        Task {
            do {
                let result = try await DeepLService.translate(
                    text: text,
                    sourceLang: newSource,
                    targetLang: newTarget
                )

                await MainActor.run {
                    resultText = result.translatedText
                    lastSourceLang = newSource
                    lastTargetLang = newTarget
                    directionLabel = "\(newSource) → \(newTarget)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func copyResult() {
        guard !resultText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resultText, forType: .string)
        withAnimation {
            copiedFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copiedFlash = false
            }
        }
    }
}

struct SwapKeyHandler: NSViewRepresentable {
    var onSwap: () -> Void
    var onCopy: () -> Void

    func makeNSView(context: Context) -> KeyHandlerView {
        let view = KeyHandlerView()
        view.onSwap = onSwap
        view.onCopy = onCopy
        return view
    }

    func updateNSView(_ nsView: KeyHandlerView, context: Context) {
        nsView.onSwap = onSwap
        nsView.onCopy = onCopy
    }

    class KeyHandlerView: NSView {
        var onSwap: (() -> Void)?
        var onCopy: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            // ⌥ + S
            if event.modifierFlags.contains(.option) && event.keyCode == 1 {
                onSwap?()
                return
            }
            // ⌘ + C (when result shown)
            if event.modifierFlags.contains(.command) && event.keyCode == 8 {
                onCopy?()
                return
            }
            super.keyDown(with: event)
        }
    }
}
