//
//  RateSessionViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 28/10/25.
//

import Foundation

final class RateSessionViewModel: ObservableObject {
    @Published var rating: Int = 5
    @Published var comment: String = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var successMessage: String?
    
    private let session: SessionSummary
    private let repository: SessionRepositoryProtocol
    private let logger: LoggerProtocol
    
    init(session: SessionSummary, repository: SessionRepositoryProtocol, logger: LoggerProtocol) {
        self.session = session
        self.repository = repository
        self.logger = logger
    }
    
    func submitRating() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        logger.info("RateSessionViewModel: Submitting rating \(rating) for session \(session.id)")
        
        do {
            try await repository.rateSession(
                id: session.id,
                rating: rating,
                comment: comment.isEmpty ? nil : comment
            )
            self.successMessage = "Thank you for your review!"
        } catch let apiError as APIError {
            switch apiError {
            case .server(let code, let message) where code == 409:
                self.errorMessage = "You have already rated this session"
                logger.error("Error: ", error: message)
            case .server(let code, let message) where code == 403:
                self.errorMessage = "You are not enrolled in this session"
                logger.error("Error: ", error: message)
            default:
                self.errorMessage = apiError.localizedDescription
            }
            logger.error("RateSessionViewModel: Failed to submit rating", error: apiError)
        } catch {
            self.errorMessage = error.localizedDescription
            logger.error("RateSessionViewModel: Unknown error", error: error)
        }
        
        isLoading = false
    }
}
