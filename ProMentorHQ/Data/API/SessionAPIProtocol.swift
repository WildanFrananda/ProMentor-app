//
//  SessionAPIProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

protocol SessionAPIProtocol {
    func fetchSession(
        page: Int,
        limit: Int,
        query: String?,
        categoryId: String?
    ) async throws -> (sessions: [SessionSummary], totalPages: Int)
    func fetchSessionDetail(id: UUID) async throws -> SessionDetail
    func joinSession(id: UUID) async throws -> Void
    func fetchHistory() async throws -> [SessionSummary]
    func rateSession(id: UUID, payload: RateSessionRequest) async throws -> Void
    func createSession(payload: CreateSessionRequest) async throws -> SessionSummary
    func fetchCategories() async throws -> [SessionCategory]
}
