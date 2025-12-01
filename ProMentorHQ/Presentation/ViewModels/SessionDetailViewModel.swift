//
//  SessionDetailViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation

enum SessionUserStatus: Equatable {
    case loading
    case coachOwner
    case joined
    case open
    case ended
}

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var sessionDetail: SessionDetail?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var joinSuccessMessage: String?
    
    @Published private(set) var userStatus: SessionUserStatus = .loading
    
    @Published private(set) var chatMessages: [ServerMessage.ChatMessagePayload] = []
    @Published private(set) var isWebSocketConnected = false
    @Published var chatInput = ""
    
    @Published private(set) var currentUserId: UUID?
    
    private let sessionId: UUID
    private let sessionRepository: SessionRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    private let storage: SecureStorageProtocol
    private let appState: AppState
    private let logger: LoggerProtocol

    private var webSocketStream: AsyncStream<ConnectionUpdate>?
    private var streamTask: Task<Void, Never>?
    
    init(
        sessionId: UUID,
        sessionRepository: SessionRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        webSocketService: WebSocketServiceProtocol,
        storage: SecureStorageProtocol,
        appState: AppState,
        logger: LoggerProtocol
    ) {
        self.sessionId = sessionId
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
        self.webSocketService = webSocketService
        self.storage = storage
        self.appState = appState
        self.logger = logger
    }
    
    func loadDetail() async -> Void {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        if currentUserId == nil {
            try? await fetchCurrentUserId()
        }
        
        do {
            let detail = try await sessionRepository.getSessionDetail(id: sessionId)
            self.sessionDetail = detail
            
            await determineUserStatus(detail: detail)
            
            logger.info("SessionDetailViewModel: Detail loaded. Status \(self.userStatus)")
        } catch {
            logger.error("SessionDetailViewModel: Failed to load detail", error: error)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinSession() async -> Void {
        guard !isLoading else { return }
        
        guard appState.authState == .authenticated else {
            self.errorMessage = "You must login to joining a session"
            return
        }
        
        isLoading = true
        errorMessage = nil
        joinSuccessMessage = nil
        
        do {
            try await sessionRepository.join(sessionId: sessionId)
            logger.info("SessionDetailViewModel: Successfully joined session \(sessionId)")
            
            self.joinSuccessMessage = "You have joined the session!"
            self.appState.activeSessionId = sessionId
            self.userStatus = .joined
            
            await connectToWebSocket()
        } catch let error as APIError {
            if case .server(let code, _) = error, code == 409 {
                self.userStatus = .joined
                self.joinSuccessMessage = "You have joined to this session"
            } else {
                logger.error("SessionDetailViewModel: Failed to join session", error: error)
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchCurrentUserId() async throws -> Void {
        let user = try await userRepository.fetchCurrenUser()
        self.currentUserId = user.id
    }
    
    private func determineUserStatus(detail: SessionDetail) async -> Void {
        if detail.startAt < Date() {
            self.userStatus = .ended
            return
        }
        
        if let userId = currentUserId, userId == detail.coach.id {
            self.userStatus = .coachOwner
            return
        }
        
        do {
            if appState.authState == .authenticated {
                let history = try await sessionRepository.getHistory()
                
                if history.contains(where: { $0.id == detail.id }) {
                    self.userStatus = .joined
                    return
                }
            }
        } catch {
            logger.warning("Failed to check history for join stasus")
        }
        
        self.userStatus = .open
    }
    
    func connectToWebSocket() async -> Void {
        guard !isWebSocketConnected else {
            logger.warning("SessionDetailViewModel: Already connected, skipping.")
            return
        }

        guard let token = try? storage.get(forKey: SecureStorageKeys.accessToken) else {
            logger.warning("SessionDetailViewModel: No token, cannot connect to WebSocket.")
            self.errorMessage = "Cannot connect to chat (session not valid)."
            return
        }
        
        streamTask?.cancel()
        streamTask = nil
        
        logger.info("SessionDetailViewModel: Connecting to WebSocket...")
        
        let stream = webSocketService.connect(sessionId: sessionId, token: token)
        self.webSocketStream = stream
        self.streamTask = Task { [weak self] in
            guard let self = self else { return }
            await self.listenForWebSocketUpdates(stream)
        }
    }
    
    private func listenForWebSocketUpdates(_ stream: AsyncStream<ConnectionUpdate>) async -> Void {
        logger.info("SessionDetailViewModel: Starting WebSocket listener task...")
        for await update in stream {
            guard !Task.isCancelled else {
                logger.info("SessionDetailViewModel: Listener task cancelled")
                break
            }
            
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
        if case .chatMessage(let payload) = message {
            chatMessages.append(payload)
        }
    }
    
    func sendChatMessage() async -> Void {
        let content = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        guard isWebSocketConnected else {
            self.errorMessage = "Not connected to chat"
            logger.warning("SessionDetailViewModel: Attempted to send message while disconnected")
            return
        }
        
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
        cleanup()
    }
    
    private func cleanup() -> Void {
        streamTask?.cancel()
        streamTask = nil
        webSocketStream = nil
        webSocketService.disconnect()
        logger.info("SessionDetailViewModel: Cleaned up resources")
        self.isWebSocketConnected = false
    }
}
