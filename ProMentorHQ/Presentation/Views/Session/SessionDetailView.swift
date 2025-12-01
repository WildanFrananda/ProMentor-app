//
//  SessionDetailView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject private var vm: SessionDetailViewModel
    @FocusState private var isInputFocused: Bool
    
    init(viewModel: SessionDetailViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                if let detail = vm.sessionDetail {
                    Section {
                        CoachHeaderView(coach: detail.coach)
                    }
                    
                    Section(header: Text("About this session")) {
                        Text(detail.description ?? "")
                    }
                    
                    Section(header: Text("Schedule")) {
                        LabeledContent("Start", value: detail.startAt.formatted(date: .abbreviated, time: .shortened))
                        if let endAt = detail.endAt {
                            LabeledContent("End", value: endAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    
                    Section {
                        actionButton
                    }
                    
                    if let success = vm.joinSuccessMessage {
                        Section {
                            Text(success)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let error = vm.errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                } else if vm.isLoading {
                    ProgressView("Loading detail...")
                }
                
                if vm.userStatus == .joined || vm.userStatus == .coachOwner {
                    Section(header: chatHeader) {
                        if vm.chatMessages.isEmpty {
                            Text("No messages yet. Say hello to everyone!")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ScrollViewReader { proxy in
                                ForEach(vm.chatMessages, id: \.id) { message in
                                    ChatBubbleView(
                                        message: message,
                                        isCurrentUser: message.sender.id == vm.currentUserId
                                    )
                                    .id(message.id)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                }
                                .onChange(of: vm.chatMessages.count) { _, _ in
                                    if let lastId = vm.chatMessages.last?.id {
                                        withAnimation {
                                            proxy.scrollTo(lastId, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.grouped)
            
            if vm.userStatus == .joined || vm.userStatus == .coachOwner {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField("Send message...", text: $vm.chatInput)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .disabled(!vm.isWebSocketConnected)
                        
                        Button {
                            Task {
                                await vm.sendChatMessage()
                            }
                        } label: {
                            Image(systemName: "paperline.fill")
                                .font(.title2)
                                .foregroundColor(vm.chatInput.isEmpty || !vm.isWebSocketConnected ? .gray : .blue)
                                .rotationEffect(.degrees(45))
                        }
                        .disabled(vm.chatInput.isEmpty || !vm.isWebSocketConnected)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle(vm.sessionDetail?.title ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadDetail()
            if vm.userStatus == .joined || vm.userStatus == .coachOwner {
                await vm.connectToWebSocket()
            }
        }
        .onDisappear {
            vm.disconnectWebSocket()
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch vm.userStatus {
        case .loading:
            ProgressView()
        case .coachOwner:
            HStack {
                Image(systemName: "mic.fill")
                Text("You are host")
            }
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .center)
        case .joined:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("You have registered")
            }
            .font(.headline)
            .foregroundColor(.green)
            .frame(maxWidth: .infinity, alignment: .center)
        case .open:
            if vm.isLoading {
                ProgressView()
            } else {
                Button("Gabung Sesi Ini") {
                    Task { await vm.joinSession() }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        case .ended:
            Text("Session ended")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
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
            Text(vm.isWebSocketConnected ? "Online" : "Connecting...")
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
