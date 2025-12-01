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
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()
    
    private let queue = DispatchQueue(label: "com.promentorhq.websocket", qos: .userInitiated)
    
    init(config: EnvironmentConfig, logger: LoggerProtocol) {
        self.config = config
        self.logger = logger
    }
    
    deinit {
        disconnect()
        urlSession.invalidateAndCancel()
    }
    
    func connect(sessionId: UUID, token: String) -> AsyncStream<ConnectionUpdate> {
        guard var components = URLComponents(url: config.webSocketBaseURL, resolvingAgainstBaseURL: false) else {
            return AsyncStream { continuation in
                continuation.yield(.error(APIError.invalidURL))
                continuation.finish()
            }
        }
        
        if components.scheme == "https" { components.scheme = "wss" }
        if components.scheme == "http" { components.scheme = "ws" }
        
        let existingPath = components.path == "/" ? "" : components.path
        components.path = "\(existingPath)/v1/ws/\(sessionId.uuidString)"
        
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        
        guard let url = components.url else {
            return AsyncStream { continuation in
                continuation.yield(.error(APIError.invalidURL))
                continuation.finish()
            }
        }
        
        logger.info("WebSocketService: Connecting to \(url.absoluteString)...")

        webSocketTask = urlSession.webSocketTask(with: url)
        
        let stream = AsyncStream(ConnectionUpdate.self) { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }
            
            continuation.onTermination =  { [weak self] _ in
                self?.logger.info("WebsocketService: Stream terminated, disconnecting")
                self?.disconnect()
            }
            
            self.listenForMessages(continuation: continuation)
            self.webSocketTask?.resume()
            continuation.yield(.connected)
        }
        
        return stream
    }
    
    func send(_ message: ClientMessage) async throws -> Void {
        let task = await getWebSocketTask()
        guard let task = task else {
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
    
    private func getWebSocketTask() async -> URLSessionWebSocketTask? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                continuation.resume(returning: self?.webSocketTask)
            }
        }
    }
    
    private func listenForMessages(continuation: AsyncStream<ConnectionUpdate>.Continuation) -> Void {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else {
                continuation.finish()
                return
            }
            
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
                    break
                }
                
                self.listenForMessages(continuation: continuation)

            case .failure(let error):
                self.logger.error("WebSocketService: Receive failed", error: error)
                continuation.yield(.error(error))
                continuation.yield(.disconnected)
                continuation.finish()
            }
        }
    }
}
