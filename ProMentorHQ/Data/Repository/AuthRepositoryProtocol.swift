//
//  AuthRepositoryProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol AuthRepositoryProtocol {
    func login(request: LoginRequest) async throws -> Void
    func register(request: RegisterRequest) async throws -> Void
    func logout() async throws -> Void
    func refreshToken() async throws -> Void
    func registerDeviceToken(_ token: String) async throws -> Void
}
