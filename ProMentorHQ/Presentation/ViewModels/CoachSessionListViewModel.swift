//
//  CoachSessionListViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 29/11/25.
//

import Foundation

@MainActor
final class CoachSessionListViewModel: ObservableObject {
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var state: ViewState = .loading
    
    private var currentPage = 1
    private var totalPages = 1
    private var canLoadMore = true
    private let limit = 10
    
    private let sessionRepository: SessionRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let appState: AppState
    private let logger: LoggerProtocol
    
    enum ViewState: Equatable {
        case loading
        case loadingNextPage
        case refreshing
        case loaded
        case empty
        case error(String)
    }
    
    init(
        sessionRepository: SessionRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        appState: AppState,
        logger: LoggerProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
        self.appState = appState
        self.logger = logger
    }
    
    func onAppear() async -> Void {
        if sessions.isEmpty {
            
        }
    }
    
    func refresh() async -> Void {
        await loadMySessions(isRefreshing: true)
    }
    
    func loadMore() async -> Void {
        guard canLoadMore, state == .loaded else { return }
        state = .loadingNextPage
        currentPage += 1
        await fetchSessions(isRefreshing: false)
    }
    
    private func loadMySessions(isRefreshing: Bool) async -> Void {
        state = isRefreshing ? .refreshing : .loading
        currentPage = 1
        canLoadMore = true
        sessions = []
        
        await fetchSessions(isRefreshing: isRefreshing)
    }
    
    private func fetchSessions(isRefreshing: Bool) async -> Void {
        do {
            var coachId = appState.currentUser?.id
            
            if coachId == nil {
                let user = try await userRepository.fetchCurrenUser()
                coachId = user.id
                appState.currentUser = user
            }
            
            guard let myId = coachId else {
                state = .error("Failed to load user profile")
                return
            }
            
            let result = try await sessionRepository.getSessions(
                page: currentPage,
                limit: limit,
                query: nil,
                categoryId: nil,
                coachId: myId.uuidString
            )
            
            let newSessions = result.sessions
            self.totalPages = result.totalPages
            self.canLoadMore = currentPage < totalPages
            
            if currentPage == 1 {
                sessions = newSessions
            } else {
                sessions.append(contentsOf: newSessions)
            }
            
            state = sessions.isEmpty ? .empty : .loaded
        } catch {
            logger.error("CoachSessionVM: Failed to fetch my sessions", error: error)
            state = .error(error.localizedDescription)
        }
    }
}
