//
//  MainTabView.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 27/10/25.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appContainer) private var container
    
    var body: some View {
        TabView {
            SessionListView(viewModel: container.makeSessionListViewModel())
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }
            
            SessionHistoryView(viewModel: container.makeSessionHistoryViewModel())
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            
            ProfileView(viewModel: container.makeProfileViewModel())
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
}
