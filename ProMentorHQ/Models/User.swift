//
//  User.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

enum UserRole: String, Codable, Equatable {
    case coach
    case attendee
    case admin
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try? container.decode(String.self)
        self = UserRole(rawValue: rawString ?? "") ?? .unknown
    }
}

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    let name: String
    let avatarUrl: String?
    let role: UserRole
    
    var isCoach: Bool {
        return role == .coach
    }
}
