import XCTest
@testable import Fren

final class DeepLResponseParsingTests: XCTestCase {

    // MARK: - Response Parsing

    func testParseValidTranslationResponse() throws {
        let json = """
        {
            "translations": [
                {
                    "detected_source_language": "FR",
                    "text": "Hello"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DeepLResponse.self, from: json)
        XCTAssertEqual(response.translations.count, 1)
        XCTAssertEqual(response.translations[0].text, "Hello")
        XCTAssertEqual(response.translations[0].detected_source_language, "FR")
    }

    func testParseMultipleTranslations() throws {
        let json = """
        {
            "translations": [
                {
                    "detected_source_language": "FR",
                    "text": "Hello"
                },
                {
                    "detected_source_language": "FR",
                    "text": "World"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DeepLResponse.self, from: json)
        XCTAssertEqual(response.translations.count, 2)
        XCTAssertEqual(response.translations[0].text, "Hello")
        XCTAssertEqual(response.translations[1].text, "World")
    }

    func testParseEmptyTranslationsArray() throws {
        let json = """
        {
            "translations": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DeepLResponse.self, from: json)
        XCTAssertTrue(response.translations.isEmpty)
    }

    func testParseMalformedJSON() {
        let json = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(DeepLResponse.self, from: json))
    }

    func testParseMissingFields() {
        let json = """
        {
            "translations": [
                {
                    "text": "Hello"
                }
            ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(DeepLResponse.self, from: json))
    }

    func testParseResponseWithUnicodeText() throws {
        let json = """
        {
            "translations": [
                {
                    "detected_source_language": "EN",
                    "text": "C'est génial ! Les accents français sont préservés."
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DeepLResponse.self, from: json)
        XCTAssertTrue(response.translations[0].text.contains("génial"))
        XCTAssertTrue(response.translations[0].text.contains("préservés"))
    }
}

final class DeepLErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(DeepLError.noAPIKey.errorDescription, "No API key configured")
        XCTAssertEqual(DeepLError.invalidURL.errorDescription, "Invalid API URL")
        XCTAssertEqual(DeepLError.invalidResponse.errorDescription, "Invalid response from DeepL")
        XCTAssertEqual(DeepLError.noTranslation.errorDescription, "No translation returned")
        XCTAssertEqual(DeepLError.apiError(statusCode: 403).errorDescription, "DeepL API error (HTTP 403)")
        XCTAssertEqual(DeepLError.apiError(statusCode: 429).errorDescription, "DeepL API error (HTTP 429)")
        XCTAssertEqual(DeepLError.apiError(statusCode: 500).errorDescription, "DeepL API error (HTTP 500)")
    }

    func testErrorConformsToLocalizedError() {
        let error: LocalizedError = DeepLError.noAPIKey
        XCTAssertNotNil(error.errorDescription)
    }
}

final class TranslationResultTests: XCTestCase {

    func testTranslationResultProperties() {
        let result = TranslationResult(
            translatedText: "Bonjour",
            detectedSourceLang: "EN",
            targetLang: "FR"
        )
        XCTAssertEqual(result.translatedText, "Bonjour")
        XCTAssertEqual(result.detectedSourceLang, "EN")
        XCTAssertEqual(result.targetLang, "FR")
    }

    func testTranslationResultWithLongText() {
        let longText = String(repeating: "Bonjour le monde. ", count: 100)
        let result = TranslationResult(
            translatedText: longText,
            detectedSourceLang: "EN",
            targetLang: "FR"
        )
        XCTAssertEqual(result.translatedText.count, longText.count)
    }
}
