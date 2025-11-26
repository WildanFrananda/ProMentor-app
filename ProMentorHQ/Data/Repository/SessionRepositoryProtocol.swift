//
//  SessionRepositoryProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

protocol SessionRepositoryProtocol {
    func getSessions(
        page: Int,
        limit: Int,
        query: String?,
        categoryId: String?
    ) async throws -> (sessions: [SessionSummary], totalPages: Int)
    func getSessionDetail(id: UUID) async throws -> SessionDetail
    func join(sessionId: UUID) async throws -> Void
    func getHistory() async throws -> [SessionSummary]
    func rateSession(id: UUID, rating: Int, comment: String?) async throws -> Void
    func createSession(
        title: String,
        description: String,
        startAt: Date,
        capacity: Int
    ) async throws -> SessionSummary
    func getCategories() async throws -> [SessionCategory]
}
