//
//  WebSocketServiceProtocol.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

enum ConnectionUpdate {
    case connected
    case disconnected
    case message(ServerMessage)
    case error(Error)
}

protocol WebSocketServiceProtocol {
    func connect(sessionId: UUID, token: String) -> AsyncStream<ConnectionUpdate>
    func send(_ message: ClientMessage) async throws -> Void
    func disconnect() -> Void
}
