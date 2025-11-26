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
    let container: AppContainer
    
    init(config: EnvironmentConfig = .localDevelopment) {
        self.container = AppContainer(config: config)
    }
}
