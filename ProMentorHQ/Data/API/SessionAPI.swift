//
//  SessionAPI.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

final class SessionAPI: SessionAPIProtocol {
    private let client: HTTPClientProtocol
    
    init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    func fetchSession(
        page: Int,
        limit: Int,
        query: String?,
        categoryId: String?
    ) async throws -> (sessions: [SessionSummary], totalPages: Int) {
        var path = "/v1/sessions?page=\(page)&limit=\(limit)"
                
        if let query = query, !query.isEmpty {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            path += "&query=\(encodedQuery)"
        }
        
        if let categoryId = categoryId {
            path += "&category_id=\(categoryId)"
        }
        
        let response: PaginatedResponse<SessionSummary> = try await client.get(path, requiresAuth: true)
        
        return (response.data, response.meta.totalPages)
    }
    
    func fetchCategories() async throws -> [SessionCategory] {
        return try await client.get("/v1/categories", requiresAuth: false)
    }
    
    func fetchSessionDetail(id: UUID) async throws -> SessionDetail {
        let path = "/v1/session-details/\(id.uuidString)"
        
        return try await client.get(path, requiresAuth: true)
    }
    
    func joinSession(id: UUID) async throws -> Void {
        let path = "/v1/sessions/\(id.uuidString)/join"
        
        let _: EmptyResponse = try await client.post(path, requiresAuth: true)
    }
    
    func fetchHistory() async throws -> [SessionSummary] {
        let path = "/v1/sessions/history"
        
        let response: [SessionSummary]? = try await client.get(path, requiresAuth: true)
        
        return response ?? []
    }
    
    func rateSession(id: UUID, payload: RateSessionRequest) async throws -> Void {
        let path = "/v1/sessions/\(id.uuidString)/rate"
        
        let _: EmptyResponse = try await client.post(path, body: payload, requiresAuth: true)
    }
    
    func createSession(payload: CreateSessionRequest) async throws -> SessionSummary {
        return try await client.post("/v1/sessions", body: payload, requiresAuth: true)
    }
}
