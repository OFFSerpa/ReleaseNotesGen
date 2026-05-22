//
//  Repository.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import Foundation

struct Repository: Codable {
    let id: Int
    let fullName: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case name
    }
}
