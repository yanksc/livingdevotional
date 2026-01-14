// ContentView - Root view that handles routing and authentication state

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.services) var services
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var profileStore = UserProfileStore.shared
    
    var body: some View {
        Group {
            // Check onboarding status first
            if !profileStore.hasCompletedOnboarding {
                OnboardingView()
            } else {
                // Check authentication state
                if let authService = services.authService, authService.isAuthenticated {
                    // Authenticated: Show main app
                    MainTabView()
                        .environmentObject(router)
                } else {
                    // Not authenticated: Show login or main app (for now)
                    // TODO: Show LoginView when auth is implemented
                    MainTabView()
                        .environmentObject(router)
                }
            }
        }
        .splashScreen()
        .onAppear {
            // Initialize NoteStore with model context
            NoteStore.shared.setModelContext(modelContext)
        }
    }
}
