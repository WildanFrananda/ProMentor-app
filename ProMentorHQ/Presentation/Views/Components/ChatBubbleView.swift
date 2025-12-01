//
//  ChatBubbleView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 29/11/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ServerMessage.ChatMessagePayload
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                avatarView(name: message.sender.name)
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.sender.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(20)
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: isCurrentUser
                            ? [.topLeft, .topRight, .bottomLeft]
                            : [.topLeft, .topRight, .bottomRight]
                        )
                    )
            }
            
            if !isCurrentUser {
                // if message from ME, Spacer has on left
                // not display own avatar
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
    
    private func avatarView(name: String) -> some View {
        let initials = name.components(separatedBy: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
        
        return ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
            Text(initials)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .frame(width: 32, height: 32)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        
        return Path(path.cgPath)
    }
}
