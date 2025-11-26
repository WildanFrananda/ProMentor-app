//
//  ProfileViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private let appState: AppState
    private let logger: LoggerProtocol
    
    init(
        userRepository: UserRepositoryProtocol,
        authRepository: AuthRepositoryProtocol,
        appState: AppState,
        logger: LoggerProtocol
    ) {
        self.userRepository = userRepository
        self.authRepository = authRepository
        self.appState = appState
        self.logger = logger
    }
    
    func loadProfile() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await userRepository.fetchCurrenUser()
            self.user = user
            logger.info("ProfileViewModel: Profile loaded")
        } catch let error as APIError {
            if case .sessionExpired = error {
                logger.warning("Profile token expired. Logging out.")
                appState.authState = .unauthenticated
                return
            }
            
            if case .server(let code, _) = error, code == 401 {
                appState.authState = .unauthenticated
                return
            }

            logger.error("ProfileViewModel: Failed to load profile", error: error)
            self.errorMessage = error.localizedDescription
        } catch {
            logger.error("ProfileViewModel: Unknown error", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() async -> Void {
        logger.info("ProfileViewModel: Logging out...")
        do {
            try await authRepository.logout()
            appState.isAuthenticated = false
        } catch {
            logger.error("ProfileViewModel: Logout failed", error: error)
            appState.isAuthenticated = false
        }
    }
    
    func updateAvatar(pickerItem: PhotosPickerItem?) async -> Void {
        guard let item = pickerItem else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw APIError.unknown(nil)
            }
            
            let updatedUser = try await userRepository.updateAvatar(imageData: imageData)
            
            self.user = updatedUser
            logger.info("ProfileViewModel: Avatar updated")
        } catch {
            logger.error("ProfileViewModel: Failed to update avatar", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
