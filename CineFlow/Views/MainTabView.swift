import SwiftUI

struct MainTabView: View {
    @ObservedObject var userProfile: UserProfile
    @State private var selectedTab = 0
    @State private var showChat = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView(userProfile: userProfile)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                WhatToWatchView()
                    .tabItem {
                        Label("What to Watch", systemImage: "sparkles")
                    }
                    .tag(1)
                
                MoviesLikeView()
                    .tabItem {
                        Label("Movies Like", systemImage: "magnifyingglass")
                    }
                    .tag(2)
                
                ProfileView(userProfile: userProfile)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.accent)
            
            // Floating CineBot button — hide on profile tab
            if selectedTab != 3 {
                Button {
                    showChat = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.goldGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 4)
                        
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView()
        }
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.background)
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textTertiary)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.accent)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
