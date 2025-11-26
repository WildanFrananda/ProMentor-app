//
//  UserRepository.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {
    private let api: UserAPIProtocol
    private let client: HTTPClientProtocol
    private let logger: LoggerProtocol
    
    init(api: UserAPIProtocol, client: HTTPClientProtocol, logger: LoggerProtocol) {
        self.api = api
        self.client = client
        self.logger = logger
    }
    
    func fetchCurrenUser() async throws -> User {
        logger.info("UserRepository: Fetching current user...")
        return try await api.getProfile()
    }
    
    func updateProfile(name: String?, avatarUrl: String?) async throws -> User {
        logger.info("UserRepository: Updating profile...")
        let request = UpdateProfileRequest(name: name, avatarUrl: avatarUrl)
        return try await api.updateProfile(request: request)
    }
    
    func updateAvatar(imageData: Data) async throws -> User {
        logger.info("UserRepository: Starting 3-step avatar upload (Proxy Mode)...")
        
        do {
            logger.debug("UserRepository: Step 1 - Fetching upload URL")
            let urlResponse = try await api.getAvatarUploadURL()
            
            guard let uploadURL = URL(string: urlResponse.uploadUrl) else {
                throw APIError.invalidURL
            }
            
            logger.debug("UserRepository: Step 2 - Uploading image to proxy \(uploadURL.absoluteString)")
            try await client.put(to: uploadURL, data: imageData)
            
            logger.debug("UserRepository: Step 3 - Saving profile with URL: \(urlResponse.finalImageUrl)")
            
            let updateRequest = UpdateProfileRequest(
                name: nil,
                avatarUrl: urlResponse.finalImageUrl
            )
            let updatedUser = try await api.updateProfile(request: updateRequest)

            logger.info("UserRepository: Avatar upload successful.")
            return updatedUser
        } catch {
            logger.error("UserRepository: Avatar upload failed", error: error)
            throw error
        }
    }
}
