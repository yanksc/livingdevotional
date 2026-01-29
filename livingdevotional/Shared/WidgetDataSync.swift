// WidgetDataSync - Syncs app data to widgets
//
// Call WidgetDataSync.shared.syncToWidget() whenever relevant data changes

import Foundation
import WidgetKit

/// Syncs main app data to widget extension via shared UserDefaults
class WidgetDataSync {
    static let shared = WidgetDataSync()
    
    // Throttling: minimum 2 seconds between syncs
    private var lastSyncTime: Date?
    private let minimumSyncInterval: TimeInterval = 2.0
    private var pendingSync = false
    
    private init() {}
    
    /// Sync all relevant data to widgets
    /// Call this when verse, streak, progress, or plan data changes
    /// Note: Calls are throttled to prevent excessive widget reloads
    @MainActor
    func syncToWidget() {
        // Throttle: skip if we synced recently
        if let lastSync = lastSyncTime, Date().timeIntervalSince(lastSync) < minimumSyncInterval {
            // Schedule a delayed sync if not already pending
            if !pendingSync {
                pendingSync = true
                let delay = minimumSyncInterval - Date().timeIntervalSince(lastSync)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.pendingSync = false
                    Task { @MainActor in
                        self?.performSync()
                    }
                }
            }
            return
        }
        
        performSync()
    }
    
    @MainActor
    private func performSync() {
        lastSyncTime = Date()
        
        let checkInStore = CheckInStore.shared
        let progressStore = ProgressStore.shared
        let readingPlanStore = ReadingPlanStore.shared
        let settingsStore = SettingsStore.shared
        
        // Get verse of the day from cache (if available)
        let verseData = getVerseData(language: settingsStore.primaryLanguage)
        
        // Get active plan info
        let activePlanInfo = getActivePlanInfo(from: readingPlanStore)
        
        // Build widget data
        let widgetData = WidgetData(
            verseText: verseData.text,
            verseReference: verseData.reference,
            verseBook: verseData.book,
            verseChapter: verseData.chapter,
            verseNumber: verseData.verse,
            verseReason: verseData.reason,
            currentStreak: checkInStore.currentStreak,
            taskCompletionStreak: checkInStore.taskCompletionStreak,
            hasReadToday: checkInStore.hasReadToday,
            hasPrayedToday: checkInStore.hasPrayedToday,
            chaptersReadToday: progressStore.getTodayReadingCount(),
            activePlanId: activePlanInfo.id,
            activePlanTitle: activePlanInfo.title,
            activePlanProgress: activePlanInfo.progress,
            activePlanDay: activePlanInfo.currentDay,
            activePlanTotal: activePlanInfo.totalDays,
            activePlanTodayReading: activePlanInfo.todayReading,
            lastUpdated: Date(),
            primaryLanguageCode: settingsStore.primaryLanguage.rawValue
        )
        
        // Save to shared UserDefaults
        WidgetDataManager.shared.saveWidgetData(widgetData)
        
        // Tell widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Force immediate sync (bypasses throttling) - use sparingly
    @MainActor
    func syncToWidgetImmediately() {
        performSync()
    }
    
    /// Sync verse data specifically (call after verse of the day updates)
    @MainActor
    func syncVerseToWidget(verse: DailyVerse, language: Language) {
        var currentData = WidgetDataManager.shared.loadWidgetData()
        
        // Update verse fields
        let widgetData = WidgetData(
            verseText: verse.text(for: language),
            verseReference: verse.reference,
            verseBook: verse.book,
            verseChapter: verse.chapter,
            verseNumber: verse.verseNumber,
            verseReason: verse.reason,
            currentStreak: currentData.currentStreak,
            taskCompletionStreak: currentData.taskCompletionStreak,
            hasReadToday: currentData.hasReadToday,
            hasPrayedToday: currentData.hasPrayedToday,
            chaptersReadToday: currentData.chaptersReadToday,
            activePlanId: currentData.activePlanId,
            activePlanTitle: currentData.activePlanTitle,
            activePlanProgress: currentData.activePlanProgress,
            activePlanDay: currentData.activePlanDay,
            activePlanTotal: currentData.activePlanTotal,
            activePlanTodayReading: currentData.activePlanTodayReading,
            lastUpdated: Date(),
            primaryLanguageCode: language.rawValue
        )
        
        WidgetDataManager.shared.saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Private Helpers
    
    private struct VerseInfo {
        let text: String
        let reference: String
        let book: String
        let chapter: Int
        let verse: Int
        let reason: String?
    }
    
    private func getVerseData(language: Language) -> VerseInfo {
        // Try to load cached verse from UserDefaults
        let userDefaults = UserDefaults.standard
        let dailyVerseKey = "dailyVerse"
        
        if let storedData = userDefaults.data(forKey: dailyVerseKey),
           let storedVerse = try? JSONDecoder().decode(DailyVerse.self, from: storedData) {
            return VerseInfo(
                text: storedVerse.text(for: language),
                reference: storedVerse.reference,
                book: storedVerse.book,
                chapter: storedVerse.chapter,
                verse: storedVerse.verseNumber,
                reason: storedVerse.reason
            )
        }
        
        // Default verse if none cached
        return VerseInfo(
            text: language == .cuv || language == .cu1 
                ? "神愛世人，甚至將他的獨生子賜給他們，叫一切信他的，不至滅亡，反得永生。"
                : "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            reference: "John 3:16",
            book: "John",
            chapter: 3,
            verse: 16,
            reason: nil
        )
    }
    
    private struct PlanInfo {
        let id: String?
        let title: String?
        let progress: Double
        let currentDay: Int?
        let totalDays: Int?
        let todayReading: String?
    }
    
    private func getActivePlanInfo(from store: ReadingPlanStore) -> PlanInfo {
        let activePlans = store.getActivePlans()
        
        guard let (plan, progress) = activePlans.first else {
            return PlanInfo(id: nil, title: nil, progress: 0, currentDay: nil, totalDays: nil, todayReading: nil)
        }
        
        // Get today's reading
        var todayReading: String? = nil
        if let todayDay = store.getTodayReading(for: plan.id) {
            todayReading = "\(todayDay.book) \(todayDay.chapter)"
        }
        
        // Calculate current day (based on completed days + 1)
        let currentDay = progress.completedDays.count + 1
        
        return PlanInfo(
            id: plan.id,
            title: plan.title,
            progress: store.getProgressPercentage(for: plan.id) / 100.0,
            currentDay: min(currentDay, plan.duration),
            totalDays: plan.duration,
            todayReading: todayReading
        )
    }
}
