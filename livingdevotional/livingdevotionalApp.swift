//
//  livingdevotionalApp.swift
//  livingdevotional
//
//  Created by Yenkai Huang on 12/29/25.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct livingdevotionalApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var router = AppRouter()
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    init() {
        // Access the singleton directly, not through the @StateObject property wrapper
        // This avoids "Accessing StateObject's object without being installed on a View" warning
        ServiceContainer.shared.registerAIService(AIService())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.services, serviceContainer)
                .environmentObject(router)
                .environment(\.locale, settingsStore.appLanguage.resolvedLocale())
                .preferredColorScheme(.light)
                .fontDesign(.serif)
                .onAppear {
                    // Request notification permission on first launch
                    Task {
                        let hasRequestedBefore = UserDefaults.standard.bool(forKey: "hasRequestedNotificationPermission")
                        if !hasRequestedBefore && settingsStore.notificationsEnabled {
                            let granted = await NotificationManager.shared.requestPermission()
                            if granted {
                                NotificationManager.shared.scheduleAllNotifications()
                            }
                            UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
                        } else if settingsStore.notificationsEnabled {
                            // Already requested before, just schedule if enabled
                            NotificationManager.shared.scheduleAllNotifications()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh notifications when app becomes active to ensure content is fresh
                    // This updates content based on current user state (e.g., if user prayed, cancel evening reminder)
                    if settingsStore.notificationsEnabled {
                        NotificationManager.shared.refreshNotifications()
                    }
                }
        }
        .modelContainer(for: SavedVerse.self)
    }
}
