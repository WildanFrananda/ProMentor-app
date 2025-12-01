//
//  Auth.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct LogoutRequest: Encodable {
    let refreshToken: String
}

struct DeviceTokenRequest: Encodable {
    let deviceToken: String
}

struct RegisterResponse: Decodable {
    let message: String
    let userId: UUID
}

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct RefreshResponse: Decodable {
    let accessToken: String
}

struct LogoutResponse: Decodable {
    let message: String
}

struct DeviceTokenResponse: Decodable {
    let message: String
}

