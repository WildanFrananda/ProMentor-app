//
//  UserAPIProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

protocol UserAPIProtocol {
    func getProfile() async throws -> User
    func updateProfile(request: UpdateProfileRequest) async throws -> User
    func getAvatarUploadURL() async throws -> AvatarUploadURLResponse
}
