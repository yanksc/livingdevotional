// ContentView - Root view that handles routing and authentication state

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.services) var services
    
    var body: some View {
        Group {
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
        .splashScreen()
    }
}
