//
//  HTTPClientProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol HTTPClientProtocol {
    init(config: EnvironmentConfig, storage: SecureStorageProtocol, logger: LoggerProtocol)
    func get<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T
    func post<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T
    func post<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T
    func put<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T
    func put(to url: URL, data: Data) async throws
}

/// Struct `EmptyResponse` for empty request
/// (200 OK or 201 Created no data).
struct EmptyResponse: Decodable, Encodable {}
