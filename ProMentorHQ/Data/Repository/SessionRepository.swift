//
//  SessionRepository.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

final class SessionRepository: SessionRepositoryProtocol {
    private let api: SessionAPIProtocol
    private let logger: LoggerProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(api: SessionAPIProtocol, logger: LoggerProtocol, authRepository: AuthRepositoryProtocol) {
        self.api = api
        self.logger = logger
        self.authRepository = authRepository
    }
    
    private func execute<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let apiError as APIError {
            if case .server(let statusCode, _) = apiError, statusCode == 401 {
                logger.warning("SessionRepository: Received 401, attempting token refresh...")
                do {
                    try await authRepository.refreshToken()
                    logger.info("SessionRepository: Token refreshed, retrying operation.")
                    return try await operation()
                } catch {
                    logger.error("SessionRepository: Refresh token failed.", error: error)
                    throw error
                }
            }
            
            throw apiError
        } catch {
            throw error
        }
    }
    
    func getSessions(
        page: Int,
        limit: Int,
        query: String?,
        categoryId: String?,
        coachId: String?
    ) async throws -> (sessions: [SessionSummary], totalPages: Int) {
        logger.info("SessionRepository: Fetching sessions (Page: \(page), Cat: \(categoryId ?? "All"), Coach: \(coachId ?? "All"))")
        
        return try await executeAuthRequest { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.api.fetchSession(
                page: page,
                limit: limit,
                query: query,
                categoryId: categoryId,
                coachId: coachId
            )
        }
    }
    
    func getCategories() async throws -> [SessionCategory] {
        return try await api.fetchCategories()
    }
    
    func getSessionDetail(id: UUID) async throws -> SessionDetail {
        logger.info("SessionRepository: Getting detail for session \(id)")
        
        return try await executeAuthRequest { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.api.fetchSessionDetail(id: id)
        }
    }
    
    func join(sessionId: UUID) async throws -> Void {
        logger.info("SessionRepository: Joining session \(sessionId)")
        return try await execute {
            try await api.joinSession(id: sessionId)
        }
    }
    
    func getHistory() async throws -> [SessionSummary] {
        logger.info("SessionRepository: Getting history")
        
        return try await executeAuthRequest { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.api.fetchHistory()
        }
    }
    
    func rateSession(id: UUID, rating: Int, comment: String?) async throws {
        logger.info("SessionRepository: Rating session \(id)")
        let payload = RateSessionRequest(rating: rating, comment: comment)
        
        return try await execute {
            try await api.rateSession(id: id, payload: payload)
        }
    }
    
    func createSession(
        title: String,
        description: String,
        startAt: Date,
        capacity: Int
    ) async throws -> SessionSummary {
        let payload = CreateSessionRequest(
            title: title,
            description: description,
            startAt: startAt,
            capacity: capacity,
            endAt: nil
        )
        return try await executeAuthRequest { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.api.createSession(payload: payload)
        }
    }
    
    private func executeAuthRequest<T>(_ request: @escaping () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch let apiError as APIError {
            guard case .server(let statusCode, _) = apiError, statusCode == 401 else { throw apiError }
            try await authRepository.refreshToken()
            return try await request()
        } catch {
            throw error
        }
    }
}
