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
        let apiURLString = "https://api.wildanfrananda.my.id"
        let wsURLString = "wss://ws.wildanfrananda.my.id"
        
        guard let apiURL = URL(string: apiURLString) else {
            fatalError("Invalid local API Base URL")
        }
        
        guard let wsURL = URL(string: wsURLString) else {
            fatalError("Invalid local WebSocket Base URL")
        }
        
        return EnvironmentConfig(baseURL: apiURL, webSocketBaseURL: wsURL)
    }
    
    static var production: EnvironmentConfig {
        return localDevelopment
    }
}
