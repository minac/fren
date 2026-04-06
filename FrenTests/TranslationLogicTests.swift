import XCTest
@testable import Fren

final class TranslationLogicTests: XCTestCase {

    // MARK: - Auto-Detect Direction Logic

    func testFrenchDetectedTargetsPrimary() {
        // When DeepL detects FR, we translate to the primary language
        let target = Config.targetLang(forDetected: "FR")
        XCTAssertEqual(target, Config.primaryLang)
    }

    func testPrimaryDetectedTargetsSecond() {
        // When DeepL detects the primary language, re-translate to second supported
        let target = Config.targetLang(forDetected: Config.primaryLang)
        XCTAssertNotEqual(target, Config.primaryLang)
    }

    func testNonSupportedLanguageDefaultsToPrimary() {
        // If an unsupported language is detected, target the primary language
        let target = Config.targetLang(forDetected: "DE")
        XCTAssertEqual(target, Config.primaryLang)
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
