//
//  RegisterViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let logger: LoggerProtocol
    
    init(authRepository: AuthRepositoryProtocol, logger: LoggerProtocol) {
        self.authRepository = authRepository
        self.logger = logger
    }
    
    func register() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let request = RegisterRequest(email: email, password: password, name: name)
        
        do {
            try await authRepository.register(request: request)
            
            logger.info("RegisterViewModel: Registration successful")
            self.successMessage = "Account registered, please log in!"
        } catch {
            logger.error("RegisterViewModel: Registration failed", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        self.isLoading = false
    }
}
