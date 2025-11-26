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
            RootView()
                .environmentObject(appContainerHolder.container.appState)
                .environment(\.appContainer, appContainerHolder.container)
                .onAppear {
                    appDelegate.appContainer = appContainerHolder.container
                    appDelegate.registerForPushNotification()
                }
        }
    }
}

