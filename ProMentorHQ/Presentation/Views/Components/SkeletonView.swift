//
//  SkeletonView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 8/11/25.
//

import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)]
                    ),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .scaleEffect(x: isAnimating ? 1.5 : 1)
            .offset(x: isAnimating ?  50 : -50)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct SessionRowSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonView()
                .frame(height: 20)
            SkeletonView()
                .frame(height: 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(width: 200)
            SkeletonView()
                .frame(height: 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(width: 150)
        }
        .padding(.vertical, 4)
    }
}
