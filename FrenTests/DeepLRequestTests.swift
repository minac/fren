import XCTest
@testable import Fren

final class DeepLRequestTests: XCTestCase {

    // MARK: - Request Body Construction

    func testRequestBodyWithoutSourceLang() throws {
        let body: [String: Any] = [
            "text": ["bonjour"],
            "target_lang": "EN"
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(decoded["target_lang"] as? String, "EN")
        XCTAssertEqual(decoded["text"] as? [String], ["bonjour"])
        XCTAssertNil(decoded["source_lang"])
    }

    func testRequestBodyWithSourceLang() throws {
        let body: [String: Any] = [
            "text": ["hello"],
            "source_lang": "EN",
            "target_lang": "FR"
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(decoded["source_lang"] as? String, "EN")
        XCTAssertEqual(decoded["target_lang"] as? String, "FR")
        XCTAssertEqual(decoded["text"] as? [String], ["hello"])
    }

    func testRequestBodyTextIsArray() throws {
        // DeepL API expects text as an array of strings
        let body: [String: Any] = [
            "text": ["test string"],
            "target_lang": "EN"
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let textArray = decoded["text"] as? [String]
        XCTAssertNotNil(textArray)
        XCTAssertEqual(textArray?.count, 1)
    }

    func testRequestBodyWithSpecialCharacters() throws {
        let body: [String: Any] = [
            "text": ["C'est l'été ! Où sont les élèves ?"],
            "target_lang": "EN"
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let text = (decoded["text"] as? [String])?.first
        XCTAssertTrue(text?.contains("l'été") == true)
    }

    // MARK: - URL Validation

    func testEndpointURLIsValid() {
        let url = URL(string: Config.deepLEndpoint)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "api-free.deepl.com")
        XCTAssertEqual(url?.path, "/v2/translate")
    }

    // MARK: - Authorization Header

    func testAuthorizationHeaderFormat() {
        let apiKey = "test-key-12345:fx"
        let header = "DeepL-Auth-Key \(apiKey)"
        XCTAssertTrue(header.hasPrefix("DeepL-Auth-Key "))
        XCTAssertTrue(header.contains(apiKey))
    }
}
