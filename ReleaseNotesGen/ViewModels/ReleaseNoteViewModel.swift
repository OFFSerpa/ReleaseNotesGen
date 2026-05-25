//
//  ReleaseNoteViewModel.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

@MainActor
final class ReleaseNoteViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var fromTag: Tag?
    @Published var toTag: Tag?
    @Published var isLoadingTags = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedMarkdown: String?
    @Published var infoMessage: String?

    var hasSameTagSelected: Bool {
        guard let from = fromTag, let to = toTag else { return false }
        return from.id == to.id
    }

    private var owner = ""
    private var repo = ""
    private var service: GitHubService?

    func setup() {
        guard let tokenStr = TokenManager.shared.token,
              let repoString = TokenManager.shared.repository else { return }

        let parts = repoString.split(separator: "/")
        guard parts.count == 2 else { return }

        owner = String(parts[0])
        repo = String(parts[1])
        service = GitHubService(token: tokenStr)

        Task { await loadTags() }
    }

    func loadTags() async {
        guard let service else { return }
        isLoadingTags = true
        errorMessage = nil

        do {
            tags = try await service.fetchTags(owner: owner, repo: repo)
            if tags.isEmpty {
                errorMessage = "This repository has no tags yet."
            } else if tags.count >= 2 {
                toTag = tags[0]
                fromTag = tags[1]
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingTags = false
    }

    func generateReleaseNotes() async {
        guard let service, let from = fromTag, let to = toTag else { return }

        isGenerating = true
        errorMessage = nil
        generatedMarkdown = nil
        infoMessage = nil

        do {
            let commits = try await service.compareCommits(owner: owner, repo: repo, base: from.name, head: to.name)
            if commits.isEmpty {
                infoMessage = "No commits found between \(from.name) and \(to.name)."
            } else {
                let categorized = CommitParser.categorize(commits: commits)
                let releaseNote = ReleaseNote(
                    fromTag: from.name,
                    toTag: to.name,
                    repository: "\(owner)/\(repo)",
                    generatedDate: Date(),
                    categorizedCommits: categorized
                )
                generatedMarkdown = CommitParser.generateMarkdown(from: releaseNote)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
