//
//  HTTPClient.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//
import Foundation

final class HTTPClient: HTTPClientProtocol {
    private let config: EnvironmentConfig
    private let storage: SecureStorageProtocol
    private let logger: LoggerProtocol
    private let decoder = JSONCoders.iso8601Decoder
    private let encoder = JSONCoders.iso8601Encoder
    
    init(config: EnvironmentConfig, storage: SecureStorageProtocol, logger: LoggerProtocol) {
        self.config = config
        self.storage = storage
        self.logger = logger
    }
    
    func get<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T {
        let request = try await buildRequest(path: path, method: "GET", body: nil as EmptyResponse?, requiresAuth: requiresAuth)
        let (data, response) = try await performRequest(request)
        return try decode(data, response: response)
    }
    
    func post<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T {
        let request = try await buildRequest(path: path, method: "POST", body: body, requiresAuth: requiresAuth)
        let (data, response) = try await performRequest(request)
        return try decode(data, response: response)
    }
    
    func post<T: Decodable>(_ path: String, requiresAuth: Bool) async throws -> T {
        let request = try await buildRequest(path: path, method: "POST", body: nil as EmptyResponse?, requiresAuth: requiresAuth)
        let (data, response) = try await performRequest(request)
        return try decode(data, response: response)
    }
    
    func put<T: Decodable, U: Encodable>(_ path: String, body: U, requiresAuth: Bool) async throws -> T {
        let request = try await buildRequest(path: path, method: "PUT", body: body, requiresAuth: requiresAuth)
        let (data, response) = try await performRequest(request)
        return try decode(data, response: response)
    }
    
    func put(to url: URL, data: Data) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        logger.debug("HTTPClient: Performing PUT (Upload) to \(url.host ?? "presigned-url")")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(nil)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error(
                "HTTPClient: File upload failed with status \(httpResponse.statusCode)",
                error: APIError.server(statusCode: httpResponse.statusCode, response: nil)
            )
            throw APIError.server(statusCode: httpResponse.statusCode, response: nil)
        }
    }
    
//    func delete(_ path: String, requiresAuth: Bool) async throws -> Void {
//        let _: EmptyResponse = try await performRequest(
//            path: path, method: "DELETE", requiresAuth: requiresAuth
//        )
//    }
    
    private func buildRequest<T: Encodable>(
        path: String,
        method: String,
        body: T?,
        requiresAuth: Bool
    ) async throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: config.baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        if (body as? EmptyResponse) == nil, let body = body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if requiresAuth {
            guard let token = try storage.get(forKey: SecureStorageKeys.accessToken) else {
                throw APIError.server(statusCode: 401, response: nil)
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        logger.debug("HTTPClient: Performing \(request.httpMethod ?? "") request to \(request.url?.path() ?? "")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown(nil)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.warning("HTTPClient: Request failed with status \(httpResponse.statusCode) for \(request.httpMethod ?? "N/A") \(request.url?.path() ?? "N/A")")
                let serverError = try? decoder.decode(ServerErrorResponse.self, from: data)
                throw APIError.server(statusCode: httpResponse.statusCode, response: serverError)
            }
            
            return (data, httpResponse)
            
        } catch let apiError as APIError {
            throw apiError
        } catch {
            logger.error("HTTPClient: Network layer error", error: error)
            throw APIError.network(error)
        }
    }
    
    private func decode<T: Decodable>(_ data: Data, response: HTTPURLResponse) throws -> T {
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("HTTPClient: Decoding failed", error: error)
            throw APIError.decoding(error)
        }
    }
}
