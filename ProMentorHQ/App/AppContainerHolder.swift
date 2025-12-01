//
//  AppContainerHolder.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import SwiftUI

@MainActor
final class AppContainerHolder: ObservableObject {
    @Published private(set) var container: AppContainer?
    @Published private(set) var isInitializing = false
    
    init(config: EnvironmentConfig = .localDevelopment) {
        Task {
            await initializeContainer(config: config)
        }
    }
    
    private func initializeContainer(config: EnvironmentConfig) async -> Void {
        self.container = await AppContainer(config: config)
        self.isInitializing = false
    }
}
