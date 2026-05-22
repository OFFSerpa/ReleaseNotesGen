//
//  SetupView.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: SetupViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "tag.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.accentColor)
                Text("ReleaseNotesGen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Connect to GitHub to get started")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GitHub Personal Access Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $viewModel.token)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Repository")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("owner/repo", text: $viewModel.repository)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 400)

            if let error = viewModel.validationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.validate() }
            } label: {
                if viewModel.isValidating {
                    ProgressView().scaleEffect(0.8).frame(width: 120)
                } else {
                    Text("Connect").frame(width: 120)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isValidating || viewModel.token.isEmpty || viewModel.repository.isEmpty)
            .keyboardShortcut(.defaultAction)

            Spacer()
        }
        .padding()
        .frame(width: 700, height: 500)
    }
}
