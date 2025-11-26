//
//  RootView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.appContainer) var container
    
    var body: some View {
        Color.brandBackground.edgesIgnoringSafeArea(.all)
            .overlay(
                ZStack {
                    switch appState.authState {
                    case .unknown:
                        ProgressView()
                    case .authenticated:
                        MainTabView()
                    case .unauthenticated:
                        AuthRootView()
                    }
                }
            )
            // Terapkan ToastView global di sini
            .toastView(toast: $appState.toast)
    }
}

@MainActor
private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer = AppContainerHolder.init(config: .localDevelopment).container
}
