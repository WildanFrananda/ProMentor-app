//
//  WebSocket.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

struct ClientMessage: Encodable {
    let msgType: String
    let content: String
    
    static func chat(content: String) -> ClientMessage {
        return ClientMessage(msgType: "chat", content: content)
    }
}

enum ServerMessage: Decodable {
    case chatMessage(ChatMessagePayload)
    case sessionJoined(SessionEventPayload)
    case sessionCreated(SessionEventPayload)
    case unknown(String) // Fallback

    struct Sender: Codable, Hashable {
        let id: UUID
        let name: String
    }
    
    struct ChatMessagePayload: Decodable, Hashable, Identifiable {
        let sender: Sender
        let content: String
        var id = UUID()
    }
    
    struct SessionEventPayload: Decodable {
        let sessionId: UUID
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
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
            self = .unknown(type)
        }
    }
}
