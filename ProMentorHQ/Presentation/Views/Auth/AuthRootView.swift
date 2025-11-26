//
//  AuthRootView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct AuthRootView: View {
    @Environment(\.appContainer) private var container
    
    var body: some View {
        NavigationStack {
            LoginView(viewModel: container.makeLoginViewModel())
        }
        .tint(.blue)
    }
}

#Preview {
    AuthRootView()
}
