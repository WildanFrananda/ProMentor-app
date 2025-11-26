//
//  CreateSessionViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 25/11/25.
//

import Foundation

@MainActor
final class CreateSessionViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var startAt: Date = Date().addingTimeInterval(3600)
    @Published var capacity: Int = 10
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isSuccess = false
    
    private let repository: SessionRepositoryProtocol
    private let logger: LoggerProtocol
    
    init(repository: SessionRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }
    
    func createSession() async -> Void {
        guard !title.isEmpty else {
            errorMessage = "Session title cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        isSuccess = false
        
        defer {
            isLoading = false
        }
        
        do {
            _ = try await repository.createSession(
                title: title,
                description: description,
                startAt: startAt,
                capacity: capacity
            )
            
            logger.info("CreateSessionViewModel: Session created successfully")
            isSuccess = true
        } catch {
            logger.error("CreateSessionViewModel: Failed to create session", error: error)
            errorMessage = error.localizedDescription
        }
    }
}
