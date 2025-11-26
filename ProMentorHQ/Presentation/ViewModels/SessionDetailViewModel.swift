//
//  SessionDetailViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var sessionDetail: SessionDetail?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var joinSuccessMessage: String?
    @Published private(set) var chatMessages: [ServerMessage.ChatMessagePayload] = []
    @Published private(set) var isWebSocketConnected = false
    @Published var chatInput = ""
    
    private let sessionId: UUID
    private let sessionRepository: SessionRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    private let storage: SecureStorageProtocol
    private let appState: AppState
    private let logger: LoggerProtocol
    private var webSocketStream: AsyncStream<ConnectionUpdate>?
    private var streamTask: Task<Void, Never>?
    
    init(
        sessionId: UUID,
        sessionRepository: SessionRepositoryProtocol,
        webSocketService: WebSocketServiceProtocol,
        storage: SecureStorageProtocol,
        appState: AppState,
        logger: LoggerProtocol
    ) {
        self.sessionId = sessionId
        self.sessionRepository = sessionRepository
        self.webSocketService = webSocketService
        self.storage = storage
        self.appState = appState
        self.logger = logger
    }
    
    func loadDetail() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let detail = try await sessionRepository.getSessionDetail(id: sessionId)
            self.sessionDetail = detail
            logger.info("SessionDetailViewModel: Detail loaded for \(sessionId)")
        } catch {
            logger.error("SessionDetailViewModel: Failed to load detail", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinSession() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        joinSuccessMessage = nil
        
        guard appState.isAuthenticated else {
            self.errorMessage = "You must login to join a session"
            self.isLoading = false
            return
        }
        
        do {
            try await sessionRepository.join(sessionId: sessionId)
            logger.info("SessionDetailViewModel: Successfully joined session \(sessionId)")
            self.joinSuccessMessage = "You have joined the session!"
            
            appState.activeSessionId = sessionId
        } catch {
            logger.error("SessionDetailViewModel: Failed to join session", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func connectToWebSocket() async -> Void {
        guard !isWebSocketConnected else { return }
        guard let token = try? storage.get(forKey: SecureStorageKeys.accessToken) else {
            logger.warning("SessionDetailViewModel: No token, cannot connect to WebSocket.")
            self.errorMessage = "Cannot connect to chat (session not valid)."
            return
        }
        
        logger.info("SessionDetailViewModel: Connecting to WebSocket...")
        
        let stream = webSocketService.connect(sessionId: sessionId, token: token)
        self.webSocketStream = stream
        self.streamTask = Task {
            await listenForWebSocketUpdates(stream)
        }
    }
    
    private func listenForWebSocketUpdates(_ stream: AsyncStream<ConnectionUpdate>) async -> Void {
        logger.info("SessionDetailViewModel: Starting WebSocket listener task...")
        for await update in stream {
            switch update {
            case .connected:
                self.isWebSocketConnected = true
                logger.info("SessionDetailViewModel: WebSocket connected.")
            case .disconnected:
                self.isWebSocketConnected = false
                logger.info("SessionDetailViewModel: WebSocket disconnected.")
            case .message(let serverMessage):
                handleServerMessages(serverMessage)
            case .error(let error):
                self.errorMessage = "Chat connection error: \(error.localizedDescription)"
                self.isWebSocketConnected = false
            }
        }
        
        logger.info("SessionDetailViewModel: WebSocket listener task finished.")
        self.isWebSocketConnected = false
    }
    
    private func handleServerMessages(_ message: ServerMessage) -> Void {
        switch message {
        case .chatMessage(let payload):
            logger.info("SessionDetailViewModel: Received chat message from \(payload.sender.name)")
            chatMessages.append(payload)
        case .sessionJoined(let payload):
            // TODO: Tampilkan notifikasi "User X joined"
            logger.info("SessionDetailViewModel: Session event \(payload.sessionId)")
        case .sessionCreated:
            break
        case .unknown(let type):
            logger.warning("SessionDetailViewModel: Received unknown WS message type: \(type)")
        }
    }
    
    func sendChatMessage() async -> Void {
        let content = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        logger.debug("SessionDetailViewModel: Sending chat message...")
        let message = ClientMessage.chat(content: content)
        
        do {
            try await webSocketService.send(message)
            self.chatInput = ""
        } catch {
            logger.error("SessionDetailViewModel: Failed to send chat message", error: error)
            self.errorMessage = "Failed sending chat"
        }
    }
    
    func disconnectWebSocket() -> Void {
        logger.info("SessionDetailViewModel: View disappearing, disconnecting WebSocket.")
        streamTask?.cancel()
        streamTask = nil
        webSocketService.disconnect()
        self.isWebSocketConnected = false
    }
}
