//
//  SetupView.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: SetupViewModel
    @State private var showSignOutConfirmation = false

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
                Text(viewModel.hasExistingToken ? "Enter the repository to connect" : "Connect to GitHub to get started")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                if viewModel.hasExistingToken {
                    // Token já existe — só mostra o repo
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repository")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("owner/repo", text: $viewModel.repository)
                            .textFieldStyle(.roundedBorder)
                    }
                } else {
                    // Fluxo completo: token + repo
                    Toggle("GitHub Enterprise", isOn: $viewModel.isEnterprise)
                        .toggleStyle(.switch)
                        .font(.caption)

                    if viewModel.isEnterprise {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("https://github.company.com", text: $viewModel.serverURL)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personal Access Token")
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
            .disabled(viewModel.isValidating || viewModel.repository.isEmpty || (!viewModel.hasExistingToken && viewModel.token.isEmpty))
            .keyboardShortcut(.defaultAction)

            if viewModel.hasExistingToken {
                Button("Sign out") { showSignOutConfirmation = true }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 700, height: 500)
        .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) { viewModel.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your GitHub token will be removed. You'll need to enter it again to reconnect.")
        }
    }
}

#Preview {
    SetupView(viewModel: .init())
}
