// UsageLimitStore - Daily limits for free users (AI questions, prayers, personalized plans)

import Foundation
import Combine

/// Tracks daily usage counts for free-tier limits. Supporters bypass all limits.
final class UsageLimitStore: ObservableObject {
    static let shared = UsageLimitStore()
    
    private let userDefaults = UserDefaults.standard
    private let aiQuestionsKey = "usageLimit_aiQuestions"
    private let aiQuestionsDateKey = "usageLimit_aiQuestionsDate"
    private let prayerGenerationsKey = "usageLimit_prayerGenerations"
    private let prayerGenerationsDateKey = "usageLimit_prayerGenerationsDate"
    private let journeyRefreshKey = "usageLimit_journeyRefresh"
    private let journeyRefreshDateKey = "usageLimit_journeyRefreshDate"
    
    static let aiQuestionsLimit = 15
    static let prayerGenerationsLimit = 2
    static let customPlansLimit = 1
    static let journeyRefreshLimit = 2
    
    private init() {}
    
    // MARK: - AI Questions (Verse AI + Ask Q&A)
    
    /// Check if user can make another AI request (explain verse or Ask Q&A). Supporters always allowed.
    func canUseAIQuestion() -> Bool {
        if SupporterService.shared.isSupporter { return true }
        ensureDateReset(prefix: "aiQuestions")
        let (count, _) = loadCount(dateKey: aiQuestionsDateKey, countKey: aiQuestionsKey)
        return count < Self.aiQuestionsLimit
    }
    
    /// Record one AI question/explanation. Call after successful use.
    func recordAIQuestionUsed() {
        guard !SupporterService.shared.isSupporter else { return }
        ensureDateReset(prefix: "aiQuestions")
        let (count, dateKey, countKey) = loadCountWithKeys(prefix: "aiQuestions")
        saveCount(count + 1, dateKey: dateKey, countKey: countKey)
    }
    
    /// Current count for today (for UI display)
    func aiQuestionsUsedToday() -> Int {
        ensureDateReset(prefix: "aiQuestions")
        let (count, _) = loadCount(dateKey: aiQuestionsDateKey, countKey: aiQuestionsKey)
        return count
    }
    
    // MARK: - Prayer Generation
    
    /// Check if user can generate another prayer today. Supporters always allowed.
    func canGeneratePrayer() -> Bool {
        if SupporterService.shared.isSupporter { return true }
        ensureDateReset(prefix: "prayer")
        let (count, _) = loadCount(dateKey: prayerGenerationsDateKey, countKey: prayerGenerationsKey)
        return count < Self.prayerGenerationsLimit
    }
    
    /// Record one prayer generation. Call after successful use.
    func recordPrayerGenerated() {
        guard !SupporterService.shared.isSupporter else { return }
        ensureDateReset(prefix: "prayer")
        let (count, dateKey, countKey) = loadCountWithKeys(prefix: "prayer")
        saveCount(count + 1, dateKey: dateKey, countKey: countKey)
    }
    
    /// Current count for today
    func prayersGeneratedToday() -> Int {
        ensureDateReset(prefix: "prayer")
        let (count, _) = loadCount(dateKey: prayerGenerationsDateKey, countKey: prayerGenerationsKey)
        return count
    }
    
    // MARK: - Custom Plans (checks ReadingPlanStore, no daily reset)
    
    /// Check if user can create another personalized plan. Supporters always allowed.
    func canCreatePersonalizedPlan() -> Bool {
        if SupporterService.shared.isSupporter { return true }
        let count = ReadingPlanStore.shared.customPlans.count
        return count < Self.customPlansLimit
    }
    
    // MARK: - Journey AI Refresh
    
    /// Check if user can refresh Journey AI analysis today. Supporters always allowed.
    func canRefreshJourneyAnalysis() -> Bool {
        if SupporterService.shared.isSupporter { return true }
        ensureDateReset(prefix: "journey")
        let (count, _) = loadCount(dateKey: journeyRefreshDateKey, countKey: journeyRefreshKey)
        return count < Self.journeyRefreshLimit
    }
    
    /// Record one journey refresh. Call after successful use.
    func recordJourneyRefreshUsed() {
        guard !SupporterService.shared.isSupporter else { return }
        ensureDateReset(prefix: "journey")
        let (count, dateKey, countKey) = loadCountWithKeys(prefix: "journey")
        saveCount(count + 1, dateKey: dateKey, countKey: countKey)
    }
    
    /// Current count for today
    func journeyRefreshesUsedToday() -> Int {
        ensureDateReset(prefix: "journey")
        let (count, _) = loadCount(dateKey: journeyRefreshDateKey, countKey: journeyRefreshKey)
        return count
    }
    
    // MARK: - Helpers
    
    private func ensureDateReset(prefix: String) {
        let (_, dateKey, countKey) = loadCountWithKeys(prefix: prefix)
        let savedDateString = userDefaults.string(forKey: dateKey) ?? ""
        let todayString = todayDateString()
        if savedDateString != todayString {
            userDefaults.set(todayString, forKey: dateKey)
            userDefaults.set(0, forKey: countKey)
        }
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    private func loadCount(dateKey: String, countKey: String) -> (Int, String) {
        let count = userDefaults.integer(forKey: countKey)
        return (count, dateKey)
    }
    
    private func loadCountWithKeys(prefix: String) -> (Int, String, String) {
        let dateKey: String
        let countKey: String
        if prefix == "aiQuestions" {
            dateKey = aiQuestionsDateKey
            countKey = aiQuestionsKey
        } else if prefix == "journey" {
            dateKey = journeyRefreshDateKey
            countKey = journeyRefreshKey
        } else {
            dateKey = prayerGenerationsDateKey
            countKey = prayerGenerationsKey
        }
        let count = userDefaults.integer(forKey: countKey)
        return (count, dateKey, countKey)
    }
    
    private func saveCount(_ count: Int, dateKey: String, countKey: String) {
        userDefaults.set(todayDateString(), forKey: dateKey)
        userDefaults.set(count, forKey: countKey)
    }
}
