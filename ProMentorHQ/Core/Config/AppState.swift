//
//  AppState.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var activeSessionId: UUID?
    @Published var themeIsDark: Bool = false
    @Published var toast: Toast? = nil
    @Published var authState: AuthState = .unknown
    private var cancellables = Set<AnyCancellable>()
    
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
    }
    
    init() {
        $authState
            .map { $0 == .authenticated }
            .assign(to: &$isAuthenticated)
    }
    
    func showToast(style: Toast.Style, message: String) -> Void {
        toast = Toast(style: style, message: message)
    }
}
