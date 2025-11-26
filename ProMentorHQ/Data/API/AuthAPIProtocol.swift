//
//  AuthAPIProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol AuthAPIProtocol {
    func register(request: RegisterRequest) async throws -> RegisterResponse
    func login(request: LoginRequest) async throws -> LoginResponse
    func refresh(request: RefreshRequest) async throws -> RefreshResponse
    func logout(request: LogoutRequest) async throws -> LogoutResponse
    func registerDeviceToken(request: DeviceTokenRequest) async throws -> DeviceTokenResponse
}
