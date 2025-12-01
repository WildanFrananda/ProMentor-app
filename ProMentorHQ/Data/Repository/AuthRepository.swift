//
//  AuthRepository.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

final class AuthRepository: AuthRepositoryProtocol {
    private let api: AuthAPIProtocol
    private let storage: SecureStorageProtocol
    private let logger: LoggerProtocol
    private let tokenRefresher = TokenRefreshActor()
    
    init(api: AuthAPIProtocol, storage: SecureStorageProtocol, logger: LoggerProtocol) {
        self.api = api
        self.storage = storage
        self.logger = logger
    }
    
    func login(request: LoginRequest) async throws -> Void {
        let response = try await api.login(request: request)
        
        try await tokenRefresher.performRefresh { [unowned self] in
            try storage.save(value: response.accessToken, forKey: SecureStorageKeys.accessToken)
            try storage.save(value: response.refreshToken, forKey: SecureStorageKeys.refreshToken)
            logger.info("AuthRepository: Login successful")
        }
    }
    
    func register(request: RegisterRequest) async throws -> Void {
        do {
            _ = try await api.register(request: request)
            logger.info("AuthRepository: Registration successful")
        } catch {
            logger.error("AuthRepository: Registration failed", error: error)
            throw error
        }
    }
    
    func logout() async throws -> Void {
        await tokenRefresher.cancelRefresh()
        
        do {
            guard let refreshToken = try storage.get(forKey: SecureStorageKeys.refreshToken) else {
                logger.warning("AuthRepository: Logout called but no refresh token found.")
                try storage.deleteAll()
                return
            }
            
            let request = LogoutRequest(refreshToken: refreshToken)
            _ = try? await api.logout(request: request)
        } catch {
            logger.error("AuthRepository: API Logout failed (proceeding to clear storage)", error: error)
        }
        
        try storage.deleteAll()
        logger.info("AuthRepository: Logout complete, storage cleared.")
    }
    
    func refreshToken() async throws -> Void {
        try await tokenRefresher.performRefresh { [unowned self] in
            logger.info("AuthRepository: Attempting token refresh...")

            guard let refreshToken = try? storage.get(forKey: SecureStorageKeys.refreshToken) else {
                logger.error("AuthRepository: Refresh failed, no refresh token.", error: nil)
                try? storage.deleteAll()
                throw APIError.sessionExpired
            }

            do {
                let request = RefreshRequest(refreshToken: refreshToken)
                let response = try await api.refresh(request: request)

                try storage.save(value: response.accessToken, forKey: SecureStorageKeys.accessToken)
                
                if !response.accessToken.isEmpty {
                    try storage.save(value: response.accessToken, forKey: SecureStorageKeys.refreshToken)
                }
                
                logger.info("AuthRepository: Token refresh successful")
            } catch let apiError as APIError {
                logger.error("AuthRepository: Refresh failed, forcing logout.", error: apiError)
                try? storage.deleteAll()
                throw APIError.sessionExpired
            } catch {
                logger.error("AuthRepository: Refresh failed (unknown error).", error: error)
                try? storage.deleteAll()
                throw APIError.sessionExpired
            }
        }
    }
    
    func registerDeviceToken(_ token: String) async throws -> Void {
        do {
            let request = DeviceTokenRequest(deviceToken: token)
            _ = try await api.registerDeviceToken(request: request)
            logger.info("AuthRepository: Device token registered")
        } catch {
            logger.error("AuthRepository: Failed to register device token", error: error)
        }
    }
}
