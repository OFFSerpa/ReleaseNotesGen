//
//  SetupViewModel.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

@MainActor
final class SetupViewModel: ObservableObject {
    @Published var token: String = ""
    @Published var repository: String = ""
    @Published var isValidating = false
    @Published var validationError: String?
    @Published var isConfigured = false

    init() {
        token = TokenManager.shared.token ?? ""
        repository = TokenManager.shared.repository ?? ""
        isConfigured = TokenManager.shared.isConfigured
    }

    func validate() async {
        guard !token.isEmpty else { validationError = "Token is required"; return }
        guard !repository.isEmpty else { validationError = "Repository is required (format: owner/repo)"; return }
        guard repository.contains("/") else { validationError = "Repository format must be owner/repo"; return }

        isValidating = true
        validationError = nil

        do {
            _ = try await GitHubService(token: token).validateToken()
            TokenManager.shared.token = token
            TokenManager.shared.repository = repository
            isConfigured = true
        } catch {
            validationError = error.localizedDescription
        }

        isValidating = false
    }

    var hasExistingToken: Bool {
        !(TokenManager.shared.token ?? "").isEmpty
    }

    func changeRepository() {
        TokenManager.shared.repository = nil
        repository = ""
        isConfigured = false
    }

    func signOut() {
        TokenManager.shared.token = nil
        TokenManager.shared.repository = nil
        token = ""
        repository = ""
        isConfigured = false
    }
}
