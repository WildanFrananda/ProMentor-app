//
//  UserAPI.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

final class UserAPI: UserAPIProtocol {
    private let client: HTTPClientProtocol
    
    init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    func getProfile() async throws -> User {
        return try await client.get("/v1/profile/me", requiresAuth: true)
    }
    
    func updateProfile(request: UpdateProfileRequest) async throws -> User {
        return try await client.put("/v1/profile/me", body: request, requiresAuth: true)
    }
    
    func getAvatarUploadURL() async throws -> AvatarUploadURLResponse {
        return try await client.post("/v1/profile/avatar/upload-url", requiresAuth: true)
    }
}
