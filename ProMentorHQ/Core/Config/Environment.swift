//
//  Environment.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

public struct EnvironmentConfig {
    let baseURL: URL
    let webSocketBaseURL: URL
}

extension EnvironmentConfig {
    static var localDevelopment: EnvironmentConfig {
        let ngrokStringUrl = "https://851e01b86bd0.ngrok-free.app"
        
        guard let apiURL = URL(string: ngrokStringUrl) else {
            fatalError("Invalid local API Base URL")
        }
        
        guard let wsURL = URL(string: ngrokStringUrl) else {
            fatalError("Invalid local WebSocket Base URL")
        }
        
        return EnvironmentConfig(baseURL: apiURL, webSocketBaseURL: wsURL)
    }
    
    static var production: EnvironmentConfig {
        guard let apiURL = URL(string: "https://api.promentorhq.com/v1") else {
            fatalError("Invalid production API Base URL")
        }
        guard let wsURL = URL(string: "wss://ws.promentorhq.com/v1/ws") else {
            fatalError("Invalid production WebSocket Base URL")
        }
        
        return EnvironmentConfig(baseURL: apiURL, webSocketBaseURL: wsURL)
    }
}
