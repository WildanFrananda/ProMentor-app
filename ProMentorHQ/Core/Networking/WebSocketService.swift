//
//  WebSocketService.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

final class WebSocketService: WebSocketServiceProtocol {
    private let config: EnvironmentConfig
    private let logger: LoggerProtocol
    private var webSocketTask: URLSessionWebSocketTask?
    private let encoder = JSONCoders.iso8601Encoder
    private let decoder = JSONCoders.iso8601Decoder
    
    init(config: EnvironmentConfig, logger: LoggerProtocol) {
        self.config = config
        self.logger = logger
    }
    
    func connect(sessionId: UUID, token: String) -> AsyncStream<ConnectionUpdate> {
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else {
            return AsyncStream { continuation in
                continuation.yield(.error(APIError.invalidURL))
                continuation.finish()
            }
        }
        
        components.scheme = config.baseURL.scheme == "https" ? "wss" : "ws"
        components.port = 8080
        components.path = "/v1/ws/\(sessionId.uuidString)"
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        
        guard let url = components.url else {
            return AsyncStream { continuation in
                continuation.yield(.error(APIError.invalidURL))
                continuation.finish()
            }
        }
        
        logger.info("WebSocketService: Connecting to \(url.path)...")
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        
        let stream = AsyncStream(ConnectionUpdate.self) { continuation in
            listenForMessages(continuation: continuation)
            webSocketTask?.resume()
            continuation.yield(.connected)
            continuation.onTermination = { [weak self] _ in
                self?.logger.info("WebSocketService: Stream terminated, disconnecting.")
                self?.disconnect()
            }
        }
        
        return stream
    }
    
    func send(_ message: ClientMessage) async throws -> Void {
        guard let task = webSocketTask else {
            throw APIError.network(URLError(.notConnectedToInternet))
        }
        
        do {
            let data = try encoder.encode(message)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw APIError.unknown()
            }
            
            logger.debug("WebSocketService: Sending message: \(jsonString)")
            try await task.send(.string(jsonString))
        } catch {
            logger.error("WebSocketService: Send failed", error: error)
            throw error
        }
    }
    
    func disconnect() -> Void {
        logger.info("WebSocketService: Disconnecting...")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func listenForMessages(continuation: AsyncStream<ConnectionUpdate>.Continuation) -> Void {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.logger.debug("WebSocketService: Received binary data (unhandled).")
                    logger.info("WebSocketService: \(data)")
                case .string(let text):
                    self.logger.debug("WebSocketService: Received string message")
                    if let data = text.data(using: .utf8) {
                        do {
                            let serverMessage = try self.decoder.decode(ServerMessage.self, from: data)
                            continuation.yield(.message(serverMessage))
                        } catch {
                            self.logger.error("WebSocketService: Failed to decode message", error: error)
                            continuation.yield(.error(APIError.decoding(error)))
                        }
                    }
                @unknown default:
                    fatalError("Unknown WebSocket message type")
                }
                
                self.listenForMessages(continuation: continuation)
            case .failure(let error):
                self.logger.error("WebSocketService: Receive failed", error: error)
                continuation.yield(.error(error))
                continuation.yield(.disconnected)
            }
        }
    }
}
