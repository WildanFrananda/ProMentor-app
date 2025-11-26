//
//  UserRepositoryProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol UserRepositoryProtocol {
    func fetchCurrenUser() async throws -> User
    func updateProfile(name: String?, avatarUrl: String?) async throws -> User
    func updateAvatar(imageData: Data) async throws -> User
}
