//
//  CreateSessionView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 25/11/25.
//

import SwiftUI

struct CreateSessionView: View {
    @StateObject private var vm: CreateSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onSessionCreated: (() -> Void)?
    
    init(viewModel: CreateSessionViewModel, onSessionCreated: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: viewModel)
        self.onSessionCreated = onSessionCreated
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session Details")) {
                    TextField("Title", text: $vm.title)
                    
                    TextField("Description", text: $vm.description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section(header: Text("Time & Capacity")) {
                    DatePicker("Start Time", selection: $vm.startAt, in: Date()...)
                    
                    Stepper("Capacity \(vm.capacity)", value: $vm.capacity, in: 1...100)
                }
                
                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button("Create Session") {
                            Task {
                                await vm.createSession()
                            }
                        }
                        .disabled(vm.title.isEmpty)
                    }
                }
            }
            .navigationTitle("Create New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: vm.isSuccess) { oldValue, newValue in
                if newValue {
                    onSessionCreated?()
                    dismiss()
                }
            }
        }
    }
}
