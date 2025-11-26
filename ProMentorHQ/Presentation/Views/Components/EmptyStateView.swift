//
//  EmptyStateView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 8/11/25.
//

import SwiftUI

struct EmptyStateView: View {
    let imageName: String
    let title: String
    let description: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: imageName)
                .font(.system(size: 60))
                .foregroundColor(.brandPrimary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.proTitle)
                    .foregroundColor(.brandTextPrimary)
                
                Text(description)
                    .font(.proBody)
                    .foregroundColor(.brandTextSecondary)
                    .multilineTextAlignment(.center)
                
                if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                    Button(buttonTitle, action: buttonAction)
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brandBackground)
        }
    }
}
