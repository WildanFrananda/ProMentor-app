//
//  SessionListViewModel.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import Foundation
import Combine

@MainActor
final class SessionListViewModel: ObservableObject {
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var categories: [SessionCategory] = []
    @Published private(set) var state: ViewState = .loading

    @Published var searchText = ""
    @Published var selectedCategory: SessionCategory? = nil
    
    private var currentPage = 1
    private var totalPages = 1
    private var isLoadingMore = false
    private var canLoadMore = true
    private let limit = 10
    
    @Published var canCreateSession: Bool = false

    private let sessionRepository: SessionRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let appState: AppState
    private let logger: LoggerProtocol

    private var cancellables = Set<AnyCancellable>()
    private var fetchTask: Task<Void, Never>?

    enum ViewState: Equatable {
        case loading
        case loadingNextPage
        case refreshing
        case loaded
        case empty(title: String, description: String)
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
        
        setupSearchDebouncer()
    }
    
    private func setupSearchDebouncer() -> Void {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.fetchTask?.cancel()
                self.fetchTask = Task {
                    await self.resetAndFetch()
                }
            }
            .store(in: &cancellables)
        
        $selectedCategory
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.fetchTask?.cancel()
                self.fetchTask = Task {
                    await self.resetAndFetch()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkUserRole() async -> Void {
        do {
            let user = try await userRepository.fetchCurrenUser()
            self.canCreateSession = user.isCoach
        } catch {
            self.canCreateSession = false
        }
    }

    func onAppear() async -> Void {
        await checkUserRole()
        
        if categories.isEmpty {
            await fetchCategories()
        }
        if sessions.isEmpty {
            state = .loading
            await fetchSessions(isRefreshing: false)
        }
    }
    
    func refreshSessions() async -> Void {
        guard state != .loading && state != .refreshing else { return }
        
        state = .refreshing
        await checkUserRole()
        await resetAndFetch(isRefreshing: true)
    }
    
    func loadMoreSessions() async -> Void {
        guard canLoadMore, state == .loaded, !isLoadingMore else { return }
        
        isLoadingMore = true
        state = .loadingNextPage
        currentPage += 1
        
        await fetchSessions(isRefreshing: false)
        isLoadingMore = false
    }
    
    private func fetchCategories() async -> Void {
        do {
            let cats = try await sessionRepository.getCategories()
            self.categories = cats
        } catch {
            logger.error("Failed to fetch categories", error: error)
        }
    }
    
    private func fetchSessions(isRefreshing: Bool) async -> Void {
        let query = searchText.isEmpty ? nil : searchText
        let catId = selectedCategory?.id
        
        do {
            let result = try await sessionRepository.getSessions(
                page: currentPage,
                limit: limit,
                query: query,
                categoryId: catId,
                coachId: nil
            )
            
            let newSessions = result.sessions
            self.totalPages = result.totalPages
            self.canLoadMore = currentPage < totalPages
            
            if currentPage == 1 {
                sessions = newSessions
            } else {
                sessions.append(contentsOf: newSessions)
            }
            
            if sessions.isEmpty {
                state = .empty(title: "No Session", description: "Try changing the search filter or keywords.")
            } else {
                state = .loaded
            }
            
        } catch let error as APIError {
            if case .sessionExpired = error {
                logger.warning("Session token expired. Logging out.")
                appState.authState = .unauthenticated
                appState.showToast(style: .warning, message: "Session expired, please login again.")
                return
            }
            
            logger.error("Failed to fetch sessions", error: error)
            appState.showToast(style: .error, message: error.localizedDescription)
            state = sessions.isEmpty 
                ? .empty(title: "Failed", description: "Tap refresh.")
                : .loaded
        } catch {
            logger.error("Unknown error", error: error)
            state = sessions.isEmpty 
                ? .empty(title: "Failed", description: "Tap refresh.")
                : .loaded
        }
    }
    
    func selectCategory(_ category: SessionCategory?) -> Void {
        selectedCategory = category
    }
    
    private func resetAndFetch(isRefreshing: Bool = false) async -> Void {
        currentPage = 1
        sessions = []
        canLoadMore = true
        state = isRefreshing ? .refreshing : .loading
        await fetchSessions(isRefreshing: isRefreshing)
    }
    
    func onDisappear() {
        fetchTask?.cancel()
        cancellables.removeAll()
    }
}
