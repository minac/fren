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
}
