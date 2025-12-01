//
//  CoachSessionListView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 29/11/25.
//

import SwiftUI

struct CoachSessionListView: View {
    @StateObject private var vm: CoachSessionListViewModel
    @Environment(\.appContainer) private var container
    @State private var isShowingCreateSheet = false
    
    init(viewModel: CoachSessionListViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .loading:
                    List {
                        ForEach(0..<3, id: \.self) { _ in
                            SessionRowSkeletonView()
                        }
                    }
                    .listStyle(.plain)
                case .empty:
                    EmptyStateView(
                        imageName: "mic.slash",
                        title: "No Session",
                        description: "You haven't created any sessions yet",
                        buttonTitle: "Create Session Now",
                        buttonAction: { isShowingCreateSheet = true }
                    )
                case .error(let message):
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(message)
                            .foregroundColor(.red)
                        Button("Try Again") {
                            Task {
                                await vm.refresh()
                            }
                        }
                    }
                case .loaded, .refreshing, .loadingNextPage:
                    List {
                        ForEach(vm.sessions) { session in
                            NavigationLink(destination: destinationView(for: session.id)) {
                                SessionRowView(session: session)
                                    .onAppear {
                                        if session.id == vm.sessions.last?.id {
                                            Task {
                                                await vm.loadMore()
                                            }
                                        }
                                    }
                            }
                        }
                        if vm.state == .loadingNextPage {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await vm.refresh()
                    }
                }
            }
            .navigationTitle("My Session")
            .task {
                await vm.onAppear()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateSessionView(
                    viewModel: container.makeCreateSessionViewModel(),
                    onSessionCreated: {
                        Task {
                            await vm.refresh()
                        }
                    }
                )
            }
        }
    }
    
    private func destinationView(for sessionId: UUID) -> some View {
        SessionDetailView(
            viewModel: container.makeSessionDetailViewModel(sessionId: sessionId)
        )
    }
}
