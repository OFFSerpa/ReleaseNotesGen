//
//  Commit.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

struct Commit: Codable, Identifiable {
    let sha: String
    let commit: CommitDetail

    var id: String { sha }
    var shortSha: String { String(sha.prefix(7)) }

    struct CommitDetail: Codable {
        let message: String
        let author: CommitAuthor
    }

    struct CommitAuthor: Codable {
        let name: String
        let date: String
    }
}
