//
//  ToastView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 8/11/25.
//

import SwiftUI

struct ToastViewModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            Spacer()
                            ToastContent(toast: toast)
                                .padding()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .animation(.spring(), value: toast)
                    }
                }
                .onChange(of: toast) { oldValue, newValue in
                    showToast()
                }
            )
    }
    
    private func showToast() -> Void {
        guard let toast = toast else { return }
        
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            withAnimation {
                self.toast = nil
            }
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }
}

struct ToastContent: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: toast.style.icon)
                .font(.title2)
                .foregroundColor(toast.style.tintColor)
            
            Text(toast.message)
                .font(.proBody)
                .foregroundColor(.brandTextPrimary)
            
            Spacer()
        }
        .padding()
        .background(Color.brandSecondaryBackground)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastViewModifier(toast: toast))
    }
}
