//
//  livingdevotionalApp.swift
//  livingdevotional
//
//  Created by Yenkai Huang on 12/29/25.
//

import SwiftUI

@main
struct livingdevotionalApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var router = AppRouter()
    
    init() {
        setupServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.services, serviceContainer)
                .environmentObject(router)
        }
    }
    
    private func setupServices() {
        // Register future services here when implemented
        // serviceContainer.registerAuthService(AuthenticationService())
        // serviceContainer.registerAIService(AIService())
    }
}
