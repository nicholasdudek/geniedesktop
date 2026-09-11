import Foundation
import Security

/// Keychain-backed storage for BYOK credentials.
///
/// The Gemini key used to live in `UserDefaults` under `PrefKey.geminiApiKey`, which
/// meant it sat in plaintext in the preference plist. Worse, earlier builds shipped a
/// hardcoded `AQ.` token as the registered default and re-injected it on every launch,
/// so clearing the field never stuck. Credentials now live here instead.
public struct GenieKeychain {
    public let service: String

    public static let gemini = GenieKeychain(service: "com.nicholasdudek.genie.geminiApiKey")
    public static let grok = GenieKeychain(service: "com.nicholasdudek.genie.grokApiKey")
    public static let deepseek = GenieKeychain(service: "com.nicholasdudek.genie.deepseekApiKey")

    private var account: String { NSUserName() }

    private var isHeadlessTest: Bool {
        CommandLine.arguments.contains("--smoke-test") ||
        CommandLine.arguments.contains("--benchmark") ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var baseQuery: [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        q[kSecUseDataProtectionKeychain as String] = true
        return q
    }

    /// Returns the stored secret, or nil when absent or unreadable.
    public func read() -> String? {
        if isHeadlessTest {
            return UserDefaults.standard.string(forKey: "genie.keychain.mock.\(service)")
        }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }
        return value
    }

    /// Writes the secret, replacing any existing item. An empty value deletes it.
    @discardableResult
    public func write(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if isHeadlessTest {
            UserDefaults.standard.set(trimmed, forKey: "genie.keychain.mock.\(service)")
            return true
        }
        guard !trimmed.isEmpty else { return delete() }
        guard let data = trimmed.data(using: .utf8) else { return false }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return true }
        if status == errSecItemNotFound {
            var insert = baseQuery
            insert.merge(attributes) { current, _ in current }
            return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        }
        return false
    }

    @discardableResult
    public func delete() -> Bool {
        if isHeadlessTest {
            UserDefaults.standard.removeObject(forKey: "genie.keychain.mock.\(service)")
            return true
        }
        let status = SecItemDelete(baseQuery as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

extension GenieKeychain {
    /// One-shot migration off `UserDefaults`. Any real key found there is moved into the
    /// Keychain; the hardcoded `AQ.` token earlier builds injected is discarded, since it
    /// is neither a `ya29.` bearer token nor an `AIza…` API key and no request built from
    /// it could ever have succeeded. Idempotent: the defaults entry is removed either way.
    public static func migrateLegacyGeminiKey(defaultsKey: String) {
        let defaults = UserDefaults.standard
        guard let legacy = defaults.string(forKey: defaultsKey) else { return }
        defaults.removeObject(forKey: defaultsKey)

        let trimmed = legacy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("AQ.") else { return }
        if gemini.read() == nil { gemini.write(trimmed) }
    }
}
