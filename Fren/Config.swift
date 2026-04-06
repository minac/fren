import Foundation
import Security

enum Config {
    static let deepLEndpoint = "https://api-free.deepl.com/v2/translate"

    /// Supported languages read from FREN_LANGUAGES env var (comma-separated, e.g. "EN,FR,PT").
    /// Defaults to ["EN", "FR"] if not set.
    static let supportedLanguages: [String] = {
        if let env = ProcessInfo.processInfo.environment["FREN_LANGUAGES"], !env.isEmpty {
            return env.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
        }
        return ["EN", "FR"]
    }()

    /// The primary language — first in the list (default "EN").
    static var primaryLang: String {
        supportedLanguages.first ?? "EN"
    }

    /// Given a detected source language, pick the best target.
    /// If detected is in the supported set, target the primary language (unless detected IS primary, then pick second).
    /// If detected is not in the supported set, target the primary language.
    static func targetLang(forDetected detected: String) -> String {
        let norm = String(detected.prefix(2)).uppercased()
        if norm == primaryLang {
            // Source is primary (EN), target the second supported language
            return supportedLanguages.count > 1 ? supportedLanguages[1] : primaryLang
        }
        // For any other supported or unsupported language, translate to primary
        return primaryLang
    }

    private static let keychainService = "com.fren.app"
    private static let keychainAccount = "deepl-api-key"

    static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setAPIKey(_ key: String) -> Bool {
        // Delete any existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: (key.data(using: .utf8) ?? Data())
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }
}
