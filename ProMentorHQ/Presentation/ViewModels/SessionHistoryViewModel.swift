//
//  SessionHistoryViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

@MainActor
final class SessionHistoryViewModel: ObservableObject {
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: SessionRepositoryProtocol
    private let logger: LoggerProtocol
    
    init(repository: SessionRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }
    
    func loadHistory() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        logger.info("SessionHistoryViewModel: Loading session history...")
        
        do {
            let historySessions = try await repository.getHistory()
            self.sessions = historySessions
        } catch {
            logger.error("SessionHistoryViewModel: Failed to load history", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
