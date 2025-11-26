//
//  Toast.swift.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 8/11/25.
//

import SwiftUI

struct Toast: Equatable {
    enum Style {
        case error, success, info, warning
        
        var tintColor: Color {
            switch self {
            case .error: return .brandError
            case .success: return .brandSuccess
            case .info: return .blue
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var style: Style
    var message: String
    var duration: Double = 3
}
