//
//  ReleaseNoteResultView.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI
import AppKit

struct ReleaseNoteResultView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            Text(markdown)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

#Preview {
    ReleaseNoteResultView(markdown: "Test")
}
