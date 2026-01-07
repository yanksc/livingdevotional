//
//  livingdevotionalApp.swift
//  livingdevotional
//
//  Created by Yenkai Huang on 12/29/25.
//

import SwiftUI
import SwiftData

@main
struct livingdevotionalApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var router = AppRouter()
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    init() {
        setupServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.services, serviceContainer)
                .environmentObject(router)
                .environment(\.locale, settingsStore.appLanguage.resolvedLocale())
        }
        .modelContainer(for: SavedVerse.self)
    }
    
    private func setupServices() {
        // Register future services here when implemented
        // serviceContainer.registerAuthService(AuthenticationService())
        // serviceContainer.registerAIService(AIService())
    }
}
