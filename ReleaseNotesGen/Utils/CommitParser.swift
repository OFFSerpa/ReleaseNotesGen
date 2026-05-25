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
            let lower = firstLine.lowercased()

            // Skip plain branch/tracking merges — they carry no meaningful info
            if lower.hasPrefix("merge branch") || lower.hasPrefix("merge remote-tracking") { continue }

            // PR merges go to their own section
            if lower.hasPrefix("merge pull request") {
                result[.mergedPRs, default: []].append(commit)
                continue
            }

            result[detectCategory(from: firstLine), default: []].append(commit)
        }
        return result
    }

    private static func detectCategory(from message: String) -> ReleaseNote.CommitCategory {
        let lower = message.lowercased()
        if lower.hasPrefix("feat:") || lower.hasPrefix("feat(") { return .features }
        if lower.hasPrefix("fix:") || lower.hasPrefix("fix(") { return .bugFixes }
        if lower.hasPrefix("perf:") || lower.hasPrefix("perf(") { return .performance }
        if lower.hasPrefix("refactor:") || lower.hasPrefix("refactor(") { return .refactors }
        if lower.hasPrefix("test:") || lower.hasPrefix("test(") || lower.hasPrefix("tests:") { return .tests }
        if lower.hasPrefix("chore:") || lower.hasPrefix("chore(") { return .chores }
        if lower.hasPrefix("docs:") || lower.hasPrefix("docs(") { return .documentation }
        return .other
    }

    // Extracts "#42 feat/my-feature" from "Merge pull request #42 from owner/feat/my-feature"
    static func formatPRTitle(from message: String) -> String {
        let pattern = #"[Mm]erge pull request #(\d+) from [^/]+/(.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return message }
        let nsMessage = message as NSString
        let range = NSRange(message.startIndex..., in: message)
        guard let match = regex.firstMatch(in: message, range: range) else { return message }
        let number = nsMessage.substring(with: match.range(at: 1))
        let branch = nsMessage.substring(with: match.range(at: 2))
        return "#\(number) \(branch)"
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
                let firstLine = commit.commit.message.components(separatedBy: "\n").first ?? commit.commit.message
                if category == .mergedPRs {
                    lines.append("- \(formatPRTitle(from: firstLine))")
                } else {
                    lines.append("- \(firstLine) (\(commit.shortSha))")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
