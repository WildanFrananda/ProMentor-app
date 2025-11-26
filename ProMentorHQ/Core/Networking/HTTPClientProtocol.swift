//
//  HTTPClientProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol HTTPClientProtocol {
    
    /// Inisialisasi sederhana.
    init(config: EnvironmentConfig, storage: SecureStorageProtocol, logger: LoggerProtocol)
    
    /// Melakukan request GET.
    func get<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T
    
    /// Melakukan request POST dengan body.
    func post<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T
    
    /// Melakukan request POST tanpa body, tapi mengharapkan respons.
    func post<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T
    
    /// Melakukan request PUT dengan body.
    func put<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T
    
    /// Melakukan request PUT khusus untuk upload file (Data).
    /// Ini menggunakan URL lengkap (presigned URL) dan tidak menyertakan auth header.
    func put(to url: URL, data: Data) async throws
    
//    func delete(_ path: String, requiresAuth: Bool) async throws -> Void
}

/// Struct `EmptyResponse` untuk request yang mengembalikan body kosong
/// (Misal: 200 OK atau 201 Created tanpa data).
struct EmptyResponse: Decodable, Encodable {}
