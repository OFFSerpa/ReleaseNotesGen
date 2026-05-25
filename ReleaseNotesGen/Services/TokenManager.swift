//
//  TokenManager.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation
import Security

final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    private let service = "br.com.viniciuspansan.ReleaseNotesGen"
    private let tokenAccount = "github_token"
    private let repoKey = "github_repo"
    private let serverURLKey = "github_server_url"

    var token: String? {
        get { readKeychain(account: tokenAccount) }
        set {
            if let newValue {
                saveKeychain(account: tokenAccount, value: newValue)
            } else {
                deleteKeychain(account: tokenAccount)
            }
        }
    }

    var repository: String? {
        get { UserDefaults.standard.string(forKey: repoKey) }
        set { UserDefaults.standard.set(newValue, forKey: repoKey) }
    }

    /// Custom GitHub Enterprise URL (nil = github.com)
    var serverURL: String? {
        get { UserDefaults.standard.string(forKey: serverURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: serverURLKey) }
    }

    /// Resolved API base URL from stored config
    var apiBaseURL: String {
        resolveBaseURL(from: serverURL)
    }

    /// Resolves the API base URL from an optional enterprise URL
    func resolveBaseURL(from enterpriseURL: String?) -> String {
        if let server = enterpriseURL, !server.isEmpty {
            let trimmed = server.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return "\(trimmed)/api/v3"
        }
        return "https://api.github.com"
    }

    var isConfigured: Bool {
        guard let token, let repo = repository else { return false }
        return !token.isEmpty && !repo.isEmpty
    }

    // MARK: - Keychain

    private func saveKeychain(account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        deleteKeychain(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
