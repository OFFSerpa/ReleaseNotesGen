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
    @Published var isEnterprise = false
    @Published var serverURL: String = ""
    @Published var isValidating = false
    @Published var validationError: String?
    @Published var isConfigured = false

    init() {
        token = TokenManager.shared.token ?? ""
        repository = TokenManager.shared.repository ?? ""
        let savedURL = TokenManager.shared.serverURL ?? ""
        serverURL = savedURL
        isEnterprise = !savedURL.isEmpty
        isConfigured = TokenManager.shared.isConfigured
    }

    func validate() async {
        guard !token.isEmpty else { validationError = "Token is required"; return }
        guard !repository.isEmpty else { validationError = "Repository is required (format: owner/repo)"; return }

        // Normalize URL → owner/repo
        repository = Self.extractOwnerRepo(from: repository)

        guard repository.contains("/") else { validationError = "Repository format must be owner/repo"; return }

        isValidating = true
        validationError = nil

        do {
            let enterpriseURL = isEnterprise ? serverURL : nil
            if isEnterprise {
                guard !serverURL.isEmpty else { validationError = "Server URL is required"; isValidating = false; return }
            }
            let baseURL = TokenManager.shared.resolveBaseURL(from: enterpriseURL)
            _ = try await GitHubService(token: token, baseURL: baseURL).validateToken()
            TokenManager.shared.token = token
            TokenManager.shared.repository = repository
            TokenManager.shared.serverURL = enterpriseURL
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

    /// Extracts "owner/repo" from a full URL or returns the input unchanged.
    /// Supports: https://github.com/owner/repo, https://github.com/owner/repo.git
    static func extractOwnerRepo(from input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.lowercased().hasPrefix("http"),
              let url = URL(string: text) else { return text }

        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else { return text }

        let owner = components[0]
        var repo = components[1]
        if repo.hasSuffix(".git") { repo = String(repo.dropLast(4)) }
        return "\(owner)/\(repo)"
    }

    // MARK: - GitHub CLI Integration

    func importTokenFromCLI() {
        validationError = nil

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        let hostname: String? = {
            guard isEnterprise, !serverURL.isEmpty,
                  let url = URL(string: serverURL),
                  let host = url.host else { return nil }
            return host
        }()

        let command = hostname != nil
            ? "gh auth token --hostname \(hostname!)"
            : "gh auth token"
        process.arguments = ["-l", "-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                validationError = hostname != nil
                    ? "Not authenticated. Run: gh auth login --hostname \(hostname!)"
                    : "Not authenticated. Run: gh auth login"
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                token = output
            } else {
                validationError = "No token returned from GitHub CLI."
            }
        } catch {
            validationError = "GitHub CLI not found. Install it with: brew install gh"
        }
    }

    func signOut() {
        TokenManager.shared.token = nil
        TokenManager.shared.repository = nil
        TokenManager.shared.serverURL = nil
        token = ""
        repository = ""
        serverURL = ""
        isEnterprise = false
        isConfigured = false
    }
}
