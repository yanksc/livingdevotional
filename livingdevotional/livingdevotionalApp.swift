//
//  livingdevotionalApp.swift
//  livingdevotional
//
//  Created by Yenkai Huang on 12/29/25.
//

import SwiftUI
import SwiftData
import UIKit
import WidgetKit
import RevenueCat

@main
struct livingdevotionalApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var router = AppRouter()
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let modelContainer: ModelContainer
    
    init() {
        // Initialize SwiftData model container with error recovery
        let container: ModelContainer
        do {
            container = try ModelContainer(for: SavedVerse.self)
        } catch {
            // If the store is corrupted, try deleting the SQLite file and recreating
            print("⚠️ SwiftData failed to load: \(error). Attempting recovery.")
            
            // Delete the corrupt store file
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                // Also remove WAL and SHM files
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            }
            
            do {
                container = try ModelContainer(for: SavedVerse.self)
            } catch {
                // Last resort: use in-memory store so the app doesn't crash
                print("⚠️ SwiftData recovery failed: \(error). Using in-memory store.")
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try! ModelContainer(for: Schema([SavedVerse.self]), configurations: memoryConfig)
            }
        }
        self.modelContainer = container
        
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        SupporterService.shared.configure()
        
        // Access the singleton directly, not through the @StateObject property wrapper
        // This avoids "Accessing StateObject's object without being installed on a View" warning
        ServiceContainer.shared.registerAIService(AIService())
        
        // Customize navigation bar title appearance: serif font + sage green color
        let sageGreen = UIColor(red: 0.659, green: 0.773, blue: 0.722, alpha: 1.0)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Large title (used by Explore, Journey, etc.)
        if let serifDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif) {
            let serifFont = UIFont(descriptor: serifDescriptor.withSymbolicTraits(.traitBold) ?? serifDescriptor, size: 0)
            appearance.largeTitleTextAttributes = [
                .foregroundColor: sageGreen,
                .font: serifFont
            ]
        }
        
        // Inline title (used by pushed views)
        if let serifInlineDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.serif) {
            let serifInlineFont = UIFont(descriptor: serifInlineDescriptor.withSymbolicTraits(.traitBold) ?? serifInlineDescriptor, size: 0)
            appearance.titleTextAttributes = [
                .foregroundColor: sageGreen,
                .font: serifInlineFont
            ]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
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
                    // Sync widget data immediately on app launch (bypass throttling)
                    Task { @MainActor in
                        WidgetDataSync.shared.syncToWidgetImmediately()
                    }
                    
                    // Schedule notifications on launch if permission was already granted during onboarding
                    if settingsStore.notificationsEnabled {
                        NotificationManager.shared.scheduleAllNotifications()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh notifications when app becomes active to ensure content is fresh
                    // This updates content based on current user state (e.g., if user prayed, cancel evening reminder)
                    if settingsStore.notificationsEnabled {
                        NotificationManager.shared.refreshNotifications()
                    }
                    
                    // Sync widget data immediately when app becomes active
                    Task { @MainActor in
                        WidgetDataSync.shared.syncToWidgetImmediately()
                    }
                }
                .onOpenURL { url in
                    // Handle deep links from widgets
                    router.handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }
}
