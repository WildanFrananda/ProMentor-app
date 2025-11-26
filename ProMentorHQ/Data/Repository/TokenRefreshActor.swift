//
//  TokenRefreshActor.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

actor TokenRefreshActor {
    private var currentTask: Task<Void, Error>?
    
    func performRefresh(_ operation: @escaping () async throws -> Void) async throws -> Void {
        if let task = currentTask {
            try await task.value
            return
        }
        
        let task = Task {
            try await operation()
        }
        
        currentTask = task
        
        do {
            try await task.value
            currentTask = nil
        } catch {
            currentTask = nil
            throw error
        }
    }
}
