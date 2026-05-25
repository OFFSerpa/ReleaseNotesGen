//
//  CommitParserTests.swift
//  ReleaseNotesGenTests
//
//  Created by Vinicius Pansan on 24/05/2026.
//

import XCTest
@testable import ReleaseNotesGen

final class CommitParserTests: XCTestCase {

    // MARK: - Helpers

    private func makeCommit(sha: String = "aabbccddeeff00112233", message: String) -> Commit {
        Commit(
            sha: sha,
            commit: Commit.CommitDetail(
                message: message,
                author: Commit.CommitAuthor(name: "Test Author", date: "2026-01-01T00:00:00Z")
            )
        )
    }

    private func makeReleaseNote(from: String = "v1.0", to: String = "v2.0", commits: [Commit]) -> ReleaseNote {
        ReleaseNote(
            fromTag: from,
            toTag: to,
            repository: "owner/repo",
            generatedDate: Date(),
            categorizedCommits: CommitParser.categorize(commits: commits)
        )
    }

    // MARK: - categorize: conventional prefixes

    func testFeatPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "feat: add login")])
        XCTAssertEqual(result[.features]?.count, 1)
    }

    func testFeatWithScope() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "feat(auth): add OAuth")])
        XCTAssertEqual(result[.features]?.count, 1)
    }

    func testFixPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "fix: resolve crash")])
        XCTAssertEqual(result[.bugFixes]?.count, 1)
    }

    func testFixWithScope() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "fix(network): handle timeout")])
        XCTAssertEqual(result[.bugFixes]?.count, 1)
    }

    func testPerfPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "perf: reduce startup time")])
        XCTAssertEqual(result[.performance]?.count, 1)
    }

    func testRefactorPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "refactor: extract service layer")])
        XCTAssertEqual(result[.refactors]?.count, 1)
    }

    func testTestPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "test: add unit tests")])
        XCTAssertEqual(result[.tests]?.count, 1)
    }

    func testTestsPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "tests: add integration tests")])
        XCTAssertEqual(result[.tests]?.count, 1)
    }

    func testChorePrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "chore: update dependencies")])
        XCTAssertEqual(result[.chores]?.count, 1)
    }

    func testDocsPrefix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "docs: update README")])
        XCTAssertEqual(result[.documentation]?.count, 1)
    }

    func testUnknownPrefixGoesToOther() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "update something random")])
        XCTAssertEqual(result[.other]?.count, 1)
    }

    // MARK: - categorize: case insensitivity

    func testCaseInsensitiveFeat() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "FEAT: add feature")])
        XCTAssertEqual(result[.features]?.count, 1)
    }

    func testCaseInsensitiveFix() {
        let result = CommitParser.categorize(commits: [makeCommit(message: "FIX: resolve issue")])
        XCTAssertEqual(result[.bugFixes]?.count, 1)
    }

    // MARK: - categorize: multiline messages

    func testOnlyFirstLineIsUsedForCategory() {
        let result = CommitParser.categorize(commits: [
            makeCommit(message: "feat: add login\n\nThis is the body.\nMore details here.")
        ])
        XCTAssertEqual(result[.features]?.count, 1)
        XCTAssertNil(result[.other])
    }

    // MARK: - categorize: merge commit handling

    func testMergePRGoesToMergedPRs() {
        let result = CommitParser.categorize(commits: [
            makeCommit(message: "Merge pull request #42 from owner/feat/my-feature")
        ])
        XCTAssertEqual(result[.mergedPRs]?.count, 1)
    }

    func testMergeBranchIsSkipped() {
        let result = CommitParser.categorize(commits: [
            makeCommit(message: "Merge branch 'main'")
        ])
        XCTAssertTrue(result.isEmpty)
    }

    func testMergeBranchIntoIsSkipped() {
        let result = CommitParser.categorize(commits: [
            makeCommit(message: "Merge branch 'feat/foo' into main")
        ])
        XCTAssertTrue(result.isEmpty)
    }

    func testMergeRemoteTrackingIsSkipped() {
        let result = CommitParser.categorize(commits: [
            makeCommit(message: "Merge remote-tracking branch 'origin/main'")
        ])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - categorize: mixed batch

    func testMixedCommitsBatchCategorizedCorrectly() {
        let commits = [
            makeCommit(message: "feat: new feature"),
            makeCommit(message: "fix: critical bug"),
            makeCommit(message: "Merge branch 'main'"),              // skipped
            makeCommit(message: "Merge pull request #7 from owner/fix/thing"),
            makeCommit(message: "chore: update CI"),
        ]
        let result = CommitParser.categorize(commits: commits)
        XCTAssertEqual(result[.features]?.count, 1)
        XCTAssertEqual(result[.bugFixes]?.count, 1)
        XCTAssertEqual(result[.mergedPRs]?.count, 1)
        XCTAssertEqual(result[.chores]?.count, 1)
        XCTAssertNil(result[.other])
        XCTAssertEqual(result.keys.count, 4)
    }

    // MARK: - formatPRTitle

    func testFormatPRTitleExtractsPRNumberAndBranch() {
        let msg = "Merge pull request #42 from owner/feat/add-login"
        XCTAssertEqual(CommitParser.formatPRTitle(from: msg), "#42 feat/add-login")
    }

    func testFormatPRTitleSingleDigitPR() {
        let msg = "Merge pull request #1 from owner/fix/crash"
        XCTAssertEqual(CommitParser.formatPRTitle(from: msg), "#1 fix/crash")
    }

    func testFormatPRTitleLargePRNumber() {
        let msg = "Merge pull request #1234 from owner/chore/cleanup"
        XCTAssertEqual(CommitParser.formatPRTitle(from: msg), "#1234 chore/cleanup")
    }

    func testFormatPRTitleUnknownFormatReturnsOriginal() {
        let msg = "some random message"
        XCTAssertEqual(CommitParser.formatPRTitle(from: msg), msg)
    }

    // MARK: - generateMarkdown

    func testMarkdownContainsTagNames() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            from: "v1.0.0", to: "v2.0.0",
            commits: [makeCommit(message: "feat: something")]
        ))
        XCTAssertTrue(md.contains("v1.0.0"))
        XCTAssertTrue(md.contains("v2.0.0"))
    }

    func testMarkdownShowsOnlyNonEmptySections() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            commits: [makeCommit(message: "feat: new feature")]
        ))
        XCTAssertTrue(md.contains("## Features"))
        XCTAssertFalse(md.contains("## Bug Fixes"))
        XCTAssertFalse(md.contains("## Other"))
    }

    func testMarkdownPRSectionFormatsTitle() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            commits: [makeCommit(message: "Merge pull request #5 from owner/feat/my-branch")]
        ))
        XCTAssertTrue(md.contains("## Pull Requests"))
        XCTAssertTrue(md.contains("#5 feat/my-branch"))
    }

    func testMarkdownPRSectionOmitsSHA() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            commits: [makeCommit(sha: "aabbccddeeff00112233",
                                 message: "Merge pull request #5 from owner/feat/my-branch")]
        ))
        XCTAssertFalse(md.contains("aabbccd"))
    }

    func testMarkdownRegularCommitIncludesSHA() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            commits: [makeCommit(sha: "aabbccddeeff00112233", message: "feat: add login")]
        ))
        XCTAssertTrue(md.contains("aabbccd"))
    }

    func testMarkdownPullRequestsSectionAppearsFirst() {
        let md = CommitParser.generateMarkdown(from: makeReleaseNote(
            commits: [
                makeCommit(message: "feat: some feature"),
                makeCommit(message: "Merge pull request #3 from owner/feat/epic")
            ]
        ))
        let prRange   = md.range(of: "## Pull Requests")
        let featRange = md.range(of: "## Features")
        XCTAssertNotNil(prRange)
        XCTAssertNotNil(featRange)
        XCTAssertLessThan(prRange!.lowerBound, featRange!.lowerBound)
    }
}
