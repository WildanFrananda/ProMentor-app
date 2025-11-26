//
//  LoginViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let appState: AppState
    private let logger: LoggerProtocol
    
    init(authRepository: AuthRepositoryProtocol, appState: AppState, logger: LoggerProtocol) {
        self.authRepository = authRepository
        self.appState = appState
        self.logger = logger
    }
    
    func login() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let request = LoginRequest(email: email, password: password)
        
        do {
            try await authRepository.login(request: request)
            
            logger.info("LoginViewModel: Login successful")
            
            appState.authState = .authenticated
            appState.showToast(style: .success, message: "Welcome back!")
        } catch {
            logger.error("LoginViewModel: Login failed", error: error)
            self.errorMessage = error.localizedDescription
            appState.showToast(style: .error, message: "Login Failed: \(error.localizedDescription)")
        }
    }
}
