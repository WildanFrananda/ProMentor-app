//
//  ProMentorHQApp.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import SwiftUI

@main
struct ProMentorHQApp: App {
    @StateObject private var appContainerHolder: AppContainerHolder
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        let config: EnvironmentConfig = .localDevelopment
        _appContainerHolder = StateObject(wrappedValue: AppContainerHolder(config: config))
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appContainerHolder.isInitializing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Initializing...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else if let container = appContainerHolder.container {
                    RootView()
                        .environmentObject(container.appState)
                        .environment(\.appContainer, container)
                        .onAppear {
                            appDelegate.appContainer = container
                            appDelegate.registerForPushNotification()
                            appDelegate.retryPushNotificationSetupIfNeeded()
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Failed to initialize app")
                            .font(.headline)
                        Text("Please restart the application")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
        }
    }
}
