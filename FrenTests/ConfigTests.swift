import XCTest
@testable import Fren

final class ConfigTests: XCTestCase {

    func testDefaultLanguagePair() {
        XCTAssertEqual(Config.sourceLang, "FR")
        XCTAssertEqual(Config.targetLang, "EN")
    }

    func testDeepLEndpoint() {
        XCTAssertEqual(Config.deepLEndpoint, "https://api-free.deepl.com/v2/translate")
        XCTAssertNotNil(URL(string: Config.deepLEndpoint))
    }

    func testEndpointIsFreeAPI() {
        XCTAssertTrue(Config.deepLEndpoint.contains("api-free"))
    }

    func testSupportedLanguagesHasDefaults() {
        // Without FREN_LANGUAGES env var, defaults to EN, FR
        XCTAssertTrue(Config.supportedLanguages.count >= 2)
        XCTAssertTrue(Config.supportedLanguages.contains("EN"))
        XCTAssertTrue(Config.supportedLanguages.contains("FR"))
    }

    func testPrimaryLangIsFirstSupported() {
        XCTAssertEqual(Config.primaryLang, Config.supportedLanguages.first)
    }

    func testTargetLangForDetectedPrimary() {
        // When detected is the primary lang, target should be the second supported
        let target = Config.targetLang(forDetected: Config.primaryLang)
        XCTAssertNotEqual(target, Config.primaryLang)
        XCTAssertEqual(target, Config.supportedLanguages[1])
    }

    func testTargetLangForDetectedNonPrimary() {
        // When detected is not primary, target should be primary
        let target = Config.targetLang(forDetected: "FR")
        if Config.primaryLang != "FR" {
            XCTAssertEqual(target, Config.primaryLang)
        }
    }

    func testTargetLangForUnknownLanguage() {
        // Unknown language should target primary
        let target = Config.targetLang(forDetected: "ZH")
        XCTAssertEqual(target, Config.primaryLang)
    }
}
