//
//  AppContainer.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import SwiftUI

@MainActor
final class AppContainer {
    let config: EnvironmentConfig
    let logger: LoggerProtocol
    let storage: SecureStorageProtocol
    let webSocketService: WebSocketServiceProtocol
    let httpClient: HTTPClientProtocol
    let appState: AppState
    
    private let authAPI: AuthAPIProtocol
    private let userAPI: UserAPIProtocol
    private let sessionAPI: SessionAPIProtocol
    
    let authRepository: AuthRepositoryProtocol
    let userRepository: UserRepositoryProtocol
    let sessionRepository: SessionRepositoryProtocol
    
    init(config: EnvironmentConfig = .localDevelopment) {
        self.config = config

        self.logger = ConsoleLogger()
        self.storage = KeychainStorage()
        self.webSocketService = WebSocketService(config: config, logger: logger)
        self.appState = AppState()

        self.httpClient = HTTPClient(config: config, storage: storage, logger: logger)

        self.authAPI = AuthAPI(client: httpClient)
        self.userAPI = UserAPI(client: httpClient)
        self.sessionAPI = SessionAPI(client: httpClient)

        self.authRepository = AuthRepository(api: authAPI, storage: storage, logger: logger)
        self.userRepository = UserRepository(api: userAPI, client: httpClient, logger: logger)
        self.sessionRepository = SessionRepository(api: sessionAPI, logger: logger, authRepository: authRepository)
        
        checkInitialAuthentication()
    }
    
    private func checkInitialAuthentication() -> Void {
        do {
            if let _ = try storage.get(forKey: SecureStorageKeys.accessToken) {
                appState.authState = .authenticated
                logger.info("AppContainer: Found existing token. User authenticated")
            } else {
                appState.authState = .unauthenticated
                logger.info("AppContainer: No token found. User not authenticated")
            }
        } catch {
            logger.error("AppContainer: Failed to read token on startup", error: error)
            appState.authState = .unauthenticated
        }
    }
    
    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(
            authRepository: authRepository,
            appState: appState,
            logger: logger
        )
    }
    
    func makeRegisterViewModel() -> RegisterViewModel {
        return RegisterViewModel(authRepository: authRepository, logger: logger)
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(
            userRepository: userRepository,
            authRepository: authRepository,
            appState: appState,
            logger: logger
        )
    }
    
    func makeSessionListViewModel() -> SessionListViewModel {
        return SessionListViewModel(
            sessionRepository: sessionRepository,
            userRepository: userRepository,
            appState: appState,
            logger: logger
        )
    }
    
    func makeSessionDetailViewModel(sessionId: UUID) -> SessionDetailViewModel {
        return SessionDetailViewModel(
            sessionId: sessionId,
            sessionRepository: sessionRepository,
            webSocketService: webSocketService,
            storage: storage,
            appState: appState,
            logger: logger
        )
    }
    
    func makeSessionHistoryViewModel() -> SessionHistoryViewModel {
        return SessionHistoryViewModel(repository: sessionRepository, logger: logger)
    }
    
    func makeRateSessionViewModel(session: SessionSummary) -> RateSessionViewModel {
        return RateSessionViewModel(
            session: session,
            repository: sessionRepository,
            logger: logger
        )
    }
    
    func makeCreateSessionViewModel() -> CreateSessionViewModel {
        return CreateSessionViewModel(repository: sessionRepository, logger: logger)
    }
}

private struct AppContainerKey: EnvironmentKey {
    static var defaultValue: AppContainer {
        // Use a nonisolated(unsafe) static to store the container
        // This is safe because AppContainer is only created on the main thread
        struct Container {
            static let shared = MainActor.assumeIsolated {
                AppContainer()
            }
        }
        return Container.shared
    }
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
