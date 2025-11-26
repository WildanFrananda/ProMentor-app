//
//  LoginView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm: LoginViewModel
    @Environment(\.appContainer) private var container
    
    init(viewModel: LoginViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section(header: Text("Welcome")) {
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
                    Button("Login") {
                        Task { await vm.login() }
                    }
                }
            }
            
            Section {
                NavigationLink("Don't have an account? Sign up here") {
                    RegisterView(viewModel: container.makeRegisterViewModel())
                }
            }
            
            if let errorMessage = vm.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }
        }
        .navigationTitle("Login")
    }
}
