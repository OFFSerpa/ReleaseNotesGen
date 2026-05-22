//
//  CommitParser.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

struct CommitParser {
    static func categorize(commits: [Commit]) -> [ReleaseNote.CommitCategory: [Commit]] {
        var result: [ReleaseNote.CommitCategory: [Commit]] = [:]
        for commit in commits {
            let firstLine = commit.commit.message.components(separatedBy: "\n").first ?? commit.commit.message
            result[detectCategory(from: firstLine), default: []].append(commit)
        }
        return result
    }

    private static func detectCategory(from message: String) -> ReleaseNote.CommitCategory {
        let lower = message.lowercased()
        if lower.hasPrefix("feat:") || lower.hasPrefix("feat(") { return .features }
        if lower.hasPrefix("fix:") || lower.hasPrefix("fix(") { return .bugFixes }
        if lower.hasPrefix("chore:") || lower.hasPrefix("chore(") { return .chores }
        if lower.hasPrefix("refactor:") || lower.hasPrefix("refactor(") { return .refactors }
        if lower.hasPrefix("docs:") || lower.hasPrefix("docs(") { return .documentation }
        return .other
    }

    static func generateMarkdown(from releaseNote: ReleaseNote) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = [
            "# Release Notes: \(releaseNote.fromTag) -> \(releaseNote.toTag)",
            "",
            "**Repository:** \(releaseNote.repository)",
            "**Generated:** \(formatter.string(from: releaseNote.generatedDate))",
            "",
        ]

        for category in ReleaseNote.CommitCategory.allCases {
            guard let commits = releaseNote.categorizedCommits[category], !commits.isEmpty else { continue }
            lines.append("## \(category.rawValue)")
            lines.append("")
            for commit in commits {
                let msg = commit.commit.message.components(separatedBy: "\n").first ?? commit.commit.message
                lines.append("- \(msg) (\(commit.shortSha))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
