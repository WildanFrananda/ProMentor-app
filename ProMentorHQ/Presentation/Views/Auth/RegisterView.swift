//
//  RegisterView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var vm: RegisterViewModel
    
    init(viewModel: RegisterViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Create new account")) {
                TextField("Full Name", text: $vm.name)
                TextField("Email", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Password", text: $vm.password)
            }
            
            Section {
                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Button("Register") {
                        Task {
                            await vm.register()
                        }
                    }
                    .disabled(vm.name.isEmpty || vm.email.isEmpty || vm.password.isEmpty)
                }
                
                if let errorMessage = vm.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
                
                if let successMessage = vm.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
//
//#Preview {
//    RegisterView()
//}
