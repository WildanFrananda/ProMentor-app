//
//  AuthAPI.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

final class AuthAPI: AuthAPIProtocol {
    private let client: HTTPClientProtocol
    
    init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    func register(request: RegisterRequest) async throws -> RegisterResponse {
        return try await client.post("/v1/auth/register", body: request, requiresAuth: false)
    }
    
    func login(request: LoginRequest) async throws -> LoginResponse {
        return try await client.post("/v1/auth/login", body: request, requiresAuth: false)
    }
    
    func refresh(request: RefreshRequest) async throws -> RefreshResponse {
        return try await client.post("/v1/auth/refresh", body: request, requiresAuth: false)
    }
    
    func logout(request: LogoutRequest) async throws -> LogoutResponse {
        return try await client.post("/v1/auth/logout", body: request, requiresAuth: false)
    }
    
    func registerDeviceToken(request: DeviceTokenRequest) async throws -> DeviceTokenResponse {
        return try await client.post("/v1/profile/device-token", body: request, requiresAuth: true)
    }
}
