// WidgetData - Data model shared between main app and widget extension
//
// NOTE: The WidgetData struct is duplicated in livingdevotional/Shared/WidgetData.swift
// and LivingPathWidget/WidgetData.swift. Both copies MUST be kept in sync.
// The Shared version also contains WidgetDataManager (used only by the main app).
// Future improvement: use dual target membership in Xcode to share a single file.
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
