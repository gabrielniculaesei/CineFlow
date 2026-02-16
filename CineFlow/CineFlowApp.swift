import SwiftUI

@main
struct CineFlowApp: App {
    @StateObject private var userProfile = UserProfile()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userProfile.hasCompletedOnboarding {
                    MainTabView(userProfile: userProfile)
                } else {
                    OnboardingView(userProfile: userProfile)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.5), value: userProfile.hasCompletedOnboarding)
        }
    }
}
