//
//  MainView.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

private enum OutputTab: String, CaseIterable {
    case raw = "Raw"
    case preview = "Preview"
}

struct MainView: View {
    @StateObject private var viewModel = ReleaseNoteViewModel()
    @ObservedObject var setupViewModel: SetupViewModel
    @State private var outputTab: OutputTab = .raw

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            content.padding()
        }
        .frame(width: 700, height: 500)
        .onAppear { viewModel.setup() }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.circle.fill")
                .foregroundColor(.accentColor)
            Text("ReleaseNotesGen")
                .font(.headline)
            Spacer()
            Text(TokenManager.shared.repository ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Change Repo") { setupViewModel.changeRepository() }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            tagSelectorRow

            if viewModel.isLoadingTags {
                loadingView("Loading tags...")
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if let markdown = viewModel.generatedMarkdown {
                outputToggle
                outputContent(markdown: markdown)
                actionButtons(markdown: markdown)
            } else {
                emptyState
            }
        }
    }

    private var tagSelectorRow: some View {
        HStack(spacing: 12) {
            tagPicker(label: "From tag", selection: $viewModel.fromTag)
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .padding(.top, 18)
            tagPicker(label: "To tag", selection: $viewModel.toTag)
            generateButton.padding(.top, 18)
        }
    }

    private func tagPicker(label: String, selection: Binding<Tag?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Picker(label, selection: selection) {
                Text("Select…").tag(Tag?.none)
                ForEach(viewModel.tags) { tag in
                    Text(tag.name).tag(tag as Tag?)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private var generateButton: some View {
        Button {
            Task { await viewModel.generateReleaseNotes() }
        } label: {
            if viewModel.isGenerating {
                ProgressView().scaleEffect(0.8).frame(width: 80)
            } else {
                Text("Generate").frame(width: 80)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isGenerating || viewModel.fromTag == nil || viewModel.toTag == nil)
    }

    private var outputToggle: some View {
        HStack {
            Picker("", selection: $outputTab) {
                ForEach(OutputTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            Spacer()
        }
    }

    @ViewBuilder
    private func outputContent(markdown: String) -> some View {
        if outputTab == .raw {
            ReleaseNoteResultView(markdown: markdown)
        } else {
            MarkdownPreviewView(markdown: markdown)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
    }

    private func actionButtons(markdown: String) -> some View {
        HStack {
            Spacer()
            Button { copyToClipboard(markdown) } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button { exportAsMarkdown(markdown) } label: {
                Label("Export .md", systemImage: "arrow.down.doc")
            }
        }
    }

    private func loadingView(_ message: String) -> some View {
        HStack { ProgressView(); Text(message).foregroundColor(.secondary) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle").font(.title).foregroundColor(.orange)
            Text(error).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Retry") { Task { await viewModel.loadTags() } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass").font(.largeTitle).foregroundColor(.secondary)
            Text("Select tags and click Generate").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func exportAsMarkdown(_ text: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "release-notes.md"
        panel.title = "Export Release Notes"
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

#Preview {
    MainView(setupViewModel: .init())
}
