//
//  APIError.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation

struct ServerErrorResponse: Decodable, Error {
    let error: String
    let details: String?
    
    var localizedDescription: String {
        return details ?? error
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case server(statusCode: Int, response: ServerErrorResponse?)
    case decoding(Error)
    case network(Error)
    case sessionExpired
    case unknown(Error? = nil)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "invalid URL"
        case .server(let code, let response):
            if let response = response {
                return "Server Error \(code): \(response.localizedDescription)"
            }
            return "Server Error \(code)"
        case .decoding(let error):
            return "Failed proccessing data: \(error.localizedDescription)"
        case .network(let error):
            return "Connection issue \(error.localizedDescription)"
        case .sessionExpired:
            return "Session expired, please login again"
        case .unknown:
            return "An unknown error occured"
        }
    }
}
