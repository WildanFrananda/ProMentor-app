//
//  TokenRefreshActor.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

actor TokenRefreshActor {
    private var currentTask: Task<Void, Error>?
    
    func performRefresh(_ operation: @Sendable @escaping () async throws -> Void) async throws -> Void {
        if let task = currentTask {
            return try await task.value
        }
        
        let task = Task {
            try await operation()
        }
        
        currentTask = task
        
        defer {
            currentTask = nil
        }
        
        try await task.value
    }
    
    func cancelRefresh() {
        currentTask?.cancel()
        currentTask = nil
    }
}
