//
//  Sessions.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

struct SessionSummary: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let startAt: Date
    let endAt: Date?
    let capacity: Int
    let coachId: UUID?
    let coachName: String?
}

struct CoachInfo: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let avatarUrl: String?
}

struct SessionDetail: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let startAt: Date
    let endAt: Date?
    let capacity: Int
    let coach: CoachInfo
    let createdAt: Date
}

struct RateSessionRequest: Encodable {
    let rating: Int
    let comment: String?
}

struct CreateSessionRequest: Encodable {
    let title: String
    let description: String?
    let startAt: Date
    let capacity: Int
    let endAt: Date?
}
