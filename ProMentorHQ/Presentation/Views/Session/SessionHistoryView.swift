//
//  SessionHistoryView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 28/10/25.
//

import SwiftUI

struct SessionHistoryView: View {
    @StateObject private var vm: SessionHistoryViewModel
    @Environment(\.appContainer) private var container
    
    @State private var sessionToRate: SessionSummary?
    
    init(viewModel: SessionHistoryViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.sessions.isEmpty {
                    ProgressView("Loading History...")
                } else if let errorMessage = vm.errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await vm.loadHistory()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if vm.sessions.isEmpty {
                    Text("You haven't attended a session yet")
                        .foregroundColor(.secondary)
                } else {
                    List(vm.sessions) { session in
                        historyRow(session: session)
                    }
                    .refreshable {
                        await vm.loadHistory()
                    }
                }
            }
            .navigationTitle("Sessions History")
            .task {
                if vm.sessions.isEmpty {
                    await vm.loadHistory()
                }
            }
            .sheet(item: $sessionToRate) { session in
                RateSessionView(
                    viewModel: container.makeRateSessionViewModel(session: session)
                )
            }
        }
    }
    
    private func historyRow(session: SessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .font(.headline)
            
            Text("Coach: \(session.coachName ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(session.startAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                sessionToRate = session
            } label: {
                Label("rate", systemImage: "start.fill")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .padding(.top, 4)
        }
    }
}
