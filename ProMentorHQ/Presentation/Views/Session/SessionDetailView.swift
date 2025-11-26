//
//  SessionDetailView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject private var vm: SessionDetailViewModel
    
    init(viewModel: SessionDetailViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if vm.isLoading && vm.sessionDetail == nil {
                ProgressView("Loading details...")
            } else if let detail = vm.sessionDetail {
                List {
                    Section {
                        CoachHeaderView(coach: detail.coach)
                    }
                    
                    Section {
                        Text(detail.description ?? "No description")
                    } header: {
                        Text("About this session")
                    }
                    
                    Section {
                        LabeledContent(
                            "Start at",
                            value: detail.startAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        if let endAt = detail.endAt {
                            LabeledContent(
                                "End at",
                                value: endAt.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    } header: {
                        Text("Schedule")
                    }
                    
                    Section {
                        if vm.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Joining...")
                                Spacer()
                            }
                        } else {
                            Button("Join this session") {
                                Task {
                                    await vm.joinSession()
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .tint(.blue)
                        }
                    }
                    
                    if let successMessage = vm.joinSuccessMessage {
                        Section {
                            Text(successMessage)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Section {
                        if vm.chatMessages.isEmpty {
                            Text("There are no messages yet. Start a conversation!")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(vm.chatMessages, id: \.id) { message in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.sender.name)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(
                                            message.sender.id == vm.sessionDetail?.id ? .blue : .secondary
                                        )
                                    
                                    Text(message.content)
                                        .font(.body)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        chatHeader
                    }
                    
                    Section {
                        HStack {
                            TextField("Type a message...", text: $vm.chatInput)
                                .textFieldStyle(.roundedBorder)
                            Button("Send") {
                                Task {
                                    await vm.sendChatMessage()
                                }
                            }
                            .disabled(vm.chatInput.isEmpty || !vm.isWebSocketConnected)
                        }
                    } footer: {
                        Text("Messages will disappear after the session ends")
                    }
                    
                    if let errorMessage = vm.errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
            } else if let errorMessage = vm.errorMessage {
                VStack(spacing: 16) {
                    Text("Failed to load")
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await vm.loadDetail()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle(vm.sessionDetail?.title ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadDetail()
            await vm.connectToWebSocket()
        }
        .onDisappear {
            vm.disconnectWebSocket()
        }
    }
    
    @ViewBuilder
    private var chatHeader: some View {
        HStack {
            Text("Live chat")
            Spacer()
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(vm.isWebSocketConnected ? .green : .red)
            Text(vm.isWebSocketConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CoachHeaderView: View {
    let coach: CoachInfo
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: coach.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(coach.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Coach")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
