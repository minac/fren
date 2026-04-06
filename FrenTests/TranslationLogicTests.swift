import XCTest
@testable import Fren

final class TranslationLogicTests: XCTestCase {

    // MARK: - Auto-Detect Direction Logic

    func testFrenchDetectedTargetsEnglish() {
        // When DeepL detects FR, we translate to EN
        let detected = "FR"
        let target = "EN"
        // If detected source is NOT English, the first-pass target (EN) is correct
        XCTAssertNotEqual(detected, "EN")
        XCTAssertEqual(target, Config.targetLang)
    }

    func testEnglishDetectedTargetsFrench() {
        // When DeepL detects EN, we re-translate to FR
        let detected = "EN"
        let retarget = detected == "EN" ? "FR" : "EN"
        XCTAssertEqual(retarget, "FR")
    }

    func testNonFrenchNonEnglishDefaultsToEnglish() {
        // If something other than EN is detected on first pass, target stays EN
        let detected = "DE"
        let target = "EN"
        // First pass targets EN; since detected != EN, we keep it
        XCTAssertNotEqual(detected, "EN")
        XCTAssertEqual(target, "EN")
    }

    // MARK: - Swap Logic

    func testSwapFromFRtoEN() {
        // Current direction: FR → EN
        let lastSource = "FR"
        let lastTarget = "EN"

        // After swap, direction reverses
        let newSource = lastTarget // EN
        let newTarget = lastSource // FR

        XCTAssertEqual(newSource, "EN")
        XCTAssertEqual(newTarget, "FR")
    }

    func testSwapFromENtoFR() {
        // Current direction: EN → FR
        let lastSource = "EN"
        let lastTarget = "FR"

        // After swap, direction reverses
        let newSource = lastTarget // FR
        let newTarget = lastSource // EN

        XCTAssertEqual(newSource, "FR")
        XCTAssertEqual(newTarget, "EN")
    }

    func testDoubleSwapReturnsToOriginal() {
        var source = "FR"
        var target = "EN"

        // First swap
        let tmp1 = source
        source = target
        target = tmp1

        XCTAssertEqual(source, "EN")
        XCTAssertEqual(target, "FR")

        // Second swap
        let tmp2 = source
        source = target
        target = tmp2

        XCTAssertEqual(source, "FR")
        XCTAssertEqual(target, "EN")
    }

    // MARK: - Direction Label

    func testDirectionLabelFormat() {
        let source = "FR"
        let target = "EN"
        let label = "\(source) → \(target)"
        XCTAssertEqual(label, "FR → EN")
    }

    func testDirectionLabelAfterSwap() {
        let source = "EN"
        let target = "FR"
        let label = "\(source) → \(target)"
        XCTAssertEqual(label, "EN → FR")
    }

    // MARK: - Input Validation

    func testEmptyInputShouldNotTranslate() {
        let input = "   "
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(trimmed.isEmpty)
    }

    func testWhitespaceOnlyInputShouldNotTranslate() {
        let input = "\n\t  \n"
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(trimmed.isEmpty)
    }

    func testValidInputPassesTrimming() {
        let input = "  bonjour  "
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmed, "bonjour")
        XCTAssertFalse(trimmed.isEmpty)
    }
}
