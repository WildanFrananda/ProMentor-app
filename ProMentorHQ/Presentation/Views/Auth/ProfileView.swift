//
//  ProfileView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var vm: ProfileViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageScale: CGFloat = 1.0
    @State private var showContent = false
    
    init(viewModel: ProfileViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            if vm.isLoading && vm.user == nil {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading profile...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let user = vm.user {
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 20)
                                    .scaleEffect(imageScale)
                                    .animation(
                                        .easeInOut(duration: 2)
                                        .repeatForever(autoreverses: true),
                                        value: imageScale
                                    )
                                
                                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.blue, .purple],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 3
                                                    )
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                                    case .failure(_), .empty:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .foregroundStyle(.gray.gradient)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 3
                                                    )
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .scaleEffect(showContent ? 1 : 0.5)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                            
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text("Change Photo")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // User Details Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("User Details")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                DetailRow(
                                    icon: "person.fill",
                                    label: "Name",
                                    value: user.name,
                                    color: .blue
                                )
                                
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                DetailRow(
                                    icon: "envelope.fill",
                                    label: "Email",
                                    value: user.email,
                                    color: .purple
                                )
                            }
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                            )
                            .padding(.horizontal, 20)
                        }
                        .offset(y: showContent ? 0 : 30)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)
                        
                        // Logout Button
                        Button(action: {
                            Task {
                                await vm.logout()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .offset(y: showContent ? 0 : 30)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        // Error Message
                        if let errorMessage = vm.errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.gradient)
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 30)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemGray6).opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await vm.loadProfile()
            withAnimation {
                showContent = true
            }
            imageScale = 1.2
        }
        .onChange(of: selectedPhoto) { oldPhoto, newPhoto in
            Task { await vm.updateAvatar(pickerItem: newPhoto) }
        }
        .overlay {
            if vm.isLoading && vm.user != nil {
                ZStack {
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                        
                        Text("Uploading...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20)
                    .scaleEffect(vm.isLoading ? 1 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.isLoading)
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color.gradient)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
