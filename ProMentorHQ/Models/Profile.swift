//
//  Profile.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

struct UpdateProfileRequest: Encodable {
    let name: String?
    let avatarUrl: String?
}

struct AvatarUploadURLResponse: Decodable {
    let uploadUrl: String
    let finalImageUrl: String
}
