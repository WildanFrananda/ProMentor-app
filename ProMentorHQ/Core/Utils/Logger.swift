//
//  Logger.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import os.log

protocol LoggerProtocol {
    func info(_ message: String)
    func debug(_ message: String)
    func warning(_ message: String)
    func error(_ message: String, error: Error?)
}

final class ConsoleLogger: LoggerProtocol {
    private let subsystem: String
    private let category: String
    private let logger: OSLog
    
    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.promentorhq",
        category: String = "Application"
    ) {
        self.subsystem = subsystem
        self.category = category
        self.logger = OSLog(subsystem: subsystem, category: category)
    }
    
    func info(_ message: String) -> Void {
        return os_log("%{public}@", log: logger, type: .info, message)
    }
    
    func debug(_ message: String) -> Void {
        return os_log("%{public}@", log: logger, type: .debug, message)
    }
    
    func warning(_ message: String) -> Void {
        return os_log("%{public}@", log: logger, type: .default, message)
    }

    func error(_ message: String, error: Error? = nil) -> Void {
        let errorMessage = "\(message) | Error: \(error?.localizedDescription ?? "N/A")"
        return os_log("%{public}@", log: logger, type: .error, errorMessage)
    }
}
