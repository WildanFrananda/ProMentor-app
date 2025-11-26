//
//  DesignSystem.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 8/11/25.
//

import SwiftUI

extension Color {
    static let brandPrimary = Color.blue
    static let brandBackground = Color(.systemGroupedBackground)
    static let brandSecondaryBackground = Color(.secondarySystemGroupedBackground)
    static let brandTextPrimary = Color.primary
    static let brandTextSecondary = Color.secondary
    static let brandError = Color.red
    static let brandSuccess = Color.green
}

extension Font {
    static func proMentor(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }
    
    static let proHeadline = proMentor(size: 24, weight: .bold)
    static let proTitle = proMentor(size: 20, weight: .semibold)
    static let proBody = proMentor(size: 16, weight: .regular)
    static let proCaption = proMentor(size: 14, weight: .medium)
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.proMentor(size: 16, weight: .bold))
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color.brandPrimary.opacity(isEnabled ? 1 : 0.5))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
