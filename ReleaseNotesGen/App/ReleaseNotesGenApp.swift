//
//  ReleaseNotesGenApp.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI

@main
struct ReleaseNotesGenApp: App {
    @StateObject private var setupViewModel = SetupViewModel()

    var body: some Scene {
        WindowGroup {
            if setupViewModel.isConfigured {
                MainView(setupViewModel: setupViewModel)
            } else {
                SetupView(viewModel: setupViewModel)
            }
        }
        .windowResizability(.contentSize)
    }
}
