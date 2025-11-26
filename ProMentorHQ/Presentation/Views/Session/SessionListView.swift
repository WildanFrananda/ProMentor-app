//
//  SessionListView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct SessionListView: View {
    @StateObject private var vm: SessionListViewModel
    @Environment(\.appContainer) private var container
    @State private var isShowingCreateSheet = false
    
    init(viewModel: SessionListViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryPill(
                                title: "All",
                                isSelected: vm.selectedCategory == nil
                            ) {
                                vm.selectCategory(nil)
                            }
                            
                            ForEach(vm.categories) { category in
                                CategoryPill(
                                    title: category.name,
                                    icon: category.icon,
                                    isSelected: vm.selectedCategory?.id == category.id
                                ) {
                                    vm.selectCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
                }
                
                Group {
                    if vm.state == .loading && vm.sessions.isEmpty {
                        List { ForEach(0..<5, id: \.self) { _ in SessionRowSkeletonView() } }.listStyle(.plain)
                    }
                    else if case .empty(let title, let description) = vm.state, vm.sessions.isEmpty {
                        EmptyStateView(
                            imageName: "magnifyingglass",
                            title: title,
                            description: description,
                            buttonTitle: "Reset Filter",
                            buttonAction: {
                                vm.searchText = ""
                                vm.selectCategory(nil)
                            }
                        )
                    }
                    else {
                        List {
                            ForEach(vm.sessions) { session in
                                NavigationLink(destination: sessionDetailDestination(session)) {
                                    SessionRowView(session: session)
                                        .onAppear {
                                            if session.id == vm.sessions.last?.id {
                                                Task { await vm.loadMoreSessions() }
                                            }
                                        }
                                }
                            }
                            if vm.state == .loadingNextPage {
                                HStack { Spacer(); ProgressView(); Spacer() }.padding()
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Upcoming Sessions")
            .searchable(text: $vm.searchText, prompt: "Find by title...")
            .refreshable { await vm.refreshSessions() }
            .task { await vm.onAppear() }
            .onDisappear { vm.onDisappear() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if vm.canCreateSession {
                        Button {
                            isShowingCreateSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateSessionView(
                    viewModel: container.makeCreateSessionViewModel(),
                    onSessionCreated: { Task { await vm.refreshSessions() } }
                )
            }
        }
    }

    private func sessionDetailDestination(_ session: SessionSummary) -> some View {
        SessionDetailView(viewModel: container.makeSessionDetailViewModel(sessionId: session.id))
    }
}

struct CategoryPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .accessibilityLabel(title)
                } else {
                    Image(systemName: "tag.fill")
                }

                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct SessionRowView: View {
    let session: SessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .font(.proMentor(size: 17, weight: .semibold))
                .foregroundColor(.brandTextPrimary)
            
            Text(session.coachName ?? "Coach Unknown")
                .font(.proMentor(size: 15, weight: .medium))
                .foregroundColor(.brandPrimary)
            
            HStack {
                Image(systemName: "calendar")
                Text(session.startAt, style: .date)
            }
            .font(.proMentor(size: 14, weight: .regular))
            .foregroundColor(.brandTextSecondary)
        }
        .padding(.vertical, 8)
    }
}
