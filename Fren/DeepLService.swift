import Foundation

struct DeepLResponse: Decodable {
    struct Translation: Decodable {
        let detected_source_language: String
        let text: String
    }
    let translations: [Translation]
}

struct TranslationResult {
    let translatedText: String
    let detectedSourceLang: String
    let targetLang: String
}

enum DeepLService {
    static func translate(
        text: String,
        sourceLang: String? = nil,
        targetLang: String
    ) async throws -> TranslationResult {
        guard let apiKey = Config.getAPIKey() else {
            throw DeepLError.noAPIKey
        }

        guard let url = URL(string: Config.deepLEndpoint) else {
            throw DeepLError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "text": [text],
            "target_lang": targetLang
        ]
        if let sourceLang {
            body["source_lang"] = sourceLang
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepLError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw DeepLError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(DeepLResponse.self, from: data)
        guard let translation = decoded.translations.first else {
            throw DeepLError.noTranslation
        }

        return TranslationResult(
            translatedText: translation.text,
            detectedSourceLang: translation.detected_source_language,
            targetLang: targetLang
        )
    }
}

enum DeepLError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noTranslation

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured"
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid response from DeepL"
        case .apiError(let code): return "DeepL API error (HTTP \(code))"
        case .noTranslation: return "No translation returned"
        }
    }
}
