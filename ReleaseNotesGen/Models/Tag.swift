//
//  Tag.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

struct Tag: Codable, Identifiable, Hashable {
    let name: String
    let commit: TagCommit

    var id: String { name }

    struct TagCommit: Codable, Hashable {
        let sha: String
    }
}
