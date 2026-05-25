//
//  GitHubService.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

enum GitHubError: LocalizedError {
    case invalidURL
    case invalidToken
    case networkError(Error)
    case decodingError(Error)
    case apiError(Int, String)
    case invalidRepository

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidToken: return "Invalid or expired token"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .apiError(let code, let msg): return "API error \(code): \(msg)"
        case .invalidRepository: return "Repository not found or access denied"
        }
    }
}

final class GitHubService {
    private let baseURL: String
    private let token: String

    init(token: String, baseURL: String = "https://api.github.com") {
        self.token = token
        self.baseURL = baseURL
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return request
    }

    // MARK: - URL Helpers

    private func encoded(_ component: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return component.addingPercentEncoding(withAllowedCharacters: allowed) ?? component
    }

    private func repoURL(_ owner: String, _ repo: String, path: String, query: String? = nil) throws -> URL {
        var urlString = "\(baseURL)/repos/\(encoded(owner))/\(encoded(repo))\(path)"
        if let query { urlString += "?\(query)" }
        guard let url = URL(string: urlString) else { throw GitHubError.invalidURL }
        return url
    }

    // MARK: - API

    func validateToken() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/user") else { throw GitHubError.invalidURL }
        let (_, response) = try await URLSession.shared.data(for: makeRequest(url: url))
        guard let http = response as? HTTPURLResponse else { return false }
        if http.statusCode == 401 { throw GitHubError.invalidToken }
        return http.statusCode == 200
    }

    func fetchTags(owner: String, repo: String) async throws -> [Tag] {
        let url = try repoURL(owner, repo, path: "/tags", query: "per_page=100")
        let (data, response) = try await URLSession.shared.data(for: makeRequest(url: url))
        guard let http = response as? HTTPURLResponse else { throw GitHubError.invalidURL }
        switch http.statusCode {
        case 200:
            do { return try JSONDecoder().decode([Tag].self, from: data) }
            catch { throw GitHubError.decodingError(error) }
        case 401: throw GitHubError.invalidToken
        case 404: throw GitHubError.invalidRepository
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GitHubError.apiError(http.statusCode, msg)
        }
    }

    func compareCommits(owner: String, repo: String, base: String, head: String) async throws -> [Commit] {
        let url = try repoURL(
            owner, repo,
            path: "/compare/\(encoded(base))...\(encoded(head))",
            query: "per_page=250"
        )
        let (data, response) = try await URLSession.shared.data(for: makeRequest(url: url))
        guard let http = response as? HTTPURLResponse else { throw GitHubError.invalidURL }
        switch http.statusCode {
        case 200:
            do {
                let compareResponse = try JSONDecoder().decode(CompareResponse.self, from: data)
                return compareResponse.commits
            } catch { throw GitHubError.decodingError(error) }
        case 401: throw GitHubError.invalidToken
        case 404: throw GitHubError.invalidRepository
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GitHubError.apiError(http.statusCode, msg)
        }
    }
}

private struct CompareResponse: Codable {
    let commits: [Commit]
}
