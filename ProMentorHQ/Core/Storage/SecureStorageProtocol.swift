//
//  SecureStorageProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol SecureStorageProtocol {
    func save(value: String, forKey key: String) throws -> Void
    func get(forKey key: String) throws -> String?
    func delete(forKey key: String) throws -> Void
    func deleteAll() throws -> Void 
}

enum SecureStorageKeys {
    static let accessToken = "promentorhq.auth.access_token"
    static let refreshToken = "promentorhq.auth.refresh_token"
}
