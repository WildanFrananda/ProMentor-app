//
//  RateSessionView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 28/10/25.
//

import SwiftUI

struct RateSessionView: View {
    @StateObject private var vm: RateSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: RateSessionViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let successMessage = vm.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                        Button("Close") {
                            dismiss()
                        }
                    }
                } else {
                    Section(header: Text("Your Rating")) {
                        Picker("Rating", selection: $vm.rating) {
                            ForEach(1...5, id: \.self) { value in
                                Text("\(value) star").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(header: Text("Comment (Optional)")) {
                        TextEditor(text: $vm.comment)
                            .frame(minHeight: 100)
                    }
                    
                    Section {
                        if vm.isLoading {
                            ProgressView("Sending...")
                        } else {
                            Button("Send rating") {
                                Task {
                                    await vm.submitRating()
                                }
                            }
                        }
                    }
                    
                    if let errorMessage = vm.errorMessage {
                        Section {
                            Text(errorMessage).foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Rate Session")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}
