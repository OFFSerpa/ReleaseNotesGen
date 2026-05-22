//
//  ReleaseNote.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

struct ReleaseNote {
    let fromTag: String
    let toTag: String
    let repository: String
    let generatedDate: Date
    let categorizedCommits: [CommitCategory: [Commit]]

    enum CommitCategory: String, CaseIterable {
        case features = "Features"
        case bugFixes = "Bug Fixes"
        case refactors = "Refactors"
        case chores = "Chores"
        case documentation = "Documentation"
        case other = "Other"
    }
}
