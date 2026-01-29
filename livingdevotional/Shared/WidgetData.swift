// WidgetData - Data model shared between main app and widget extension
//
// This model contains all data needed to render widget views

import Foundation

/// Data structure shared with widgets via App Group UserDefaults
struct WidgetData: Codable {
    // MARK: - Verse of the Day
    let verseText: String           // Primary language verse text
    let verseReference: String      // e.g., "John 3:16"
    let verseBook: String           // Book name for navigation
    let verseChapter: Int           // Chapter number for navigation
    let verseNumber: Int            // Verse number for navigation
    let verseReason: String?        // "From your prayer about..."
    
    // MARK: - Streak Data
    let currentStreak: Int          // App open streak
    let taskCompletionStreak: Int   // Read + pray streak
    let hasReadToday: Bool          // Reading status
    let hasPrayedToday: Bool        // Prayer status
    
    // MARK: - Reading Progress
    let chaptersReadToday: Int      // Chapters read today
    
    // MARK: - Active Reading Plan
    let activePlanId: String?       // Plan ID for deep linking
    let activePlanTitle: String?    // Plan title
    let activePlanProgress: Double  // Progress 0.0-1.0
    let activePlanDay: Int?         // Current day number
    let activePlanTotal: Int?       // Total days in plan
    let activePlanTodayReading: String? // e.g., "John 3"
    
    // MARK: - Metadata
    let lastUpdated: Date
    let primaryLanguageCode: String // For localization
    
    // MARK: - Computed Properties
    
    /// Check if the verse is in Chinese (Traditional or Simplified)
    var isChineseVerse: Bool {
        primaryLanguageCode == "cuv" || primaryLanguageCode == "cu1"
    }
    
    /// Create empty/default widget data
    static var empty: WidgetData {
        WidgetData(
            verseText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            verseReference: "John 3:16",
            verseBook: "John",
            verseChapter: 3,
            verseNumber: 16,
            verseReason: nil,
            currentStreak: 0,
            taskCompletionStreak: 0,
            hasReadToday: false,
            hasPrayedToday: false,
            chaptersReadToday: 0,
            activePlanId: nil,
            activePlanTitle: nil,
            activePlanProgress: 0,
            activePlanDay: nil,
            activePlanTotal: nil,
            activePlanTodayReading: nil,
            lastUpdated: Date(),
            primaryLanguageCode: "en"
        )
    }
}

// MARK: - Widget Data Manager

/// Manages reading and writing widget data to shared UserDefaults
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private init() {}
    
    /// Load widget data from shared UserDefaults
    func loadWidgetData() -> WidgetData {
        guard let sharedDefaults = AppGroupConfig.sharedUserDefaults,
              let data = sharedDefaults.data(forKey: AppGroupConfig.Keys.widgetData),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return widgetData
    }
    
    /// Save widget data to shared UserDefaults
    func saveWidgetData(_ widgetData: WidgetData) {
        guard let sharedDefaults = AppGroupConfig.sharedUserDefaults,
              let data = try? JSONEncoder().encode(widgetData) else {
            return
        }
        sharedDefaults.set(data, forKey: AppGroupConfig.Keys.widgetData)
        sharedDefaults.set(Date(), forKey: AppGroupConfig.Keys.lastSyncDate)
    }
    
    /// Check if widget data needs refresh (older than 1 hour or from different day)
    func needsRefresh() -> Bool {
        guard let sharedDefaults = AppGroupConfig.sharedUserDefaults,
              let lastSync = sharedDefaults.object(forKey: AppGroupConfig.Keys.lastSyncDate) as? Date else {
            return true
        }
        
        // Refresh if older than 1 hour or from a different day
        let hourAgo = Date().addingTimeInterval(-3600)
        let sameDay = Calendar.current.isDateInToday(lastSync)
        
        return lastSync < hourAgo || !sameDay
    }
}
