//
//  WebSocketMessage.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

struct ClientMessage: Encodable {
    let msgType: String
    let content: String
}

struct ChatSenderInfo: Decodable, Equatable {
    let id: UUID
    let name: String
}

struct ChatMessagePayload: Decodable, Equatable, Identifiable {
    let id = UUID()
    let sender: ChatSenderInfo
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case sender
        case content
    }
}

struct SessionEventPayload: Decodable, Equatable {
    let sessionId: UUID
}

enum ServerMessage: Decodable, Equatable {
    case chatMessage(ChatMessagePayload)
    case sessionJoined(SessionEventPayload)
    case sessionCreated(SessionEventPayload)
    case unknown(String)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try decoder.decode(String.self, forKey: .type)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch type {
        case "chat_message":
            let payload = try singleValueContainer.decode(ChatMessagePayload.self)
            self = .chatMessage(payload)
        case "session.joined":
            let payload = try singleValueContainer.decode(SessionEventPayload.self)
            self = .sessionJoined(payload)
        case "session.created":
            let payload = try singleValueContainer.decode(SessionEventPayload.self)
            self = .sessionCreated(payload)
        default:
            
        }
    }
}
