// CheckInStore - Manages daily check-ins and streaks
//
// Tracks:
// 1. App Open (automatic)
// 2. Prayer Check-in (manual)
//

import Foundation
import Combine
import WidgetKit

enum CheckInType: String, Codable {
    case appOpen
    case prayer
    case reading
}

struct DailyRecord: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String // YYYY-MM-DD
    private var typesArray: [CheckInType]
    var lastUpdated: Date
    
    var types: Set<CheckInType> {
        get { Set(typesArray) }
        set { typesArray = Array(newValue) }
    }
    
    // Helper to check status
    var hasPrayed: Bool { types.contains(.prayer) }
    var hasOpenedApp: Bool { types.contains(.appOpen) }
    var hasReadToday: Bool { types.contains(.reading) }
    var hasCompletedDailyTasks: Bool { hasReadToday && hasPrayed }
    
    init(dateString: String, types: Set<CheckInType>, lastUpdated: Date) {
        self.dateString = dateString
        self.typesArray = Array(types)
        self.lastUpdated = lastUpdated
    }
    
    enum CodingKeys: String, CodingKey {
        case dateString
        case typesArray
        case lastUpdated
    }
}

class CheckInStore: ObservableObject {
    static let shared = CheckInStore()
    
    private let userDefaults = UserDefaults.standard
    private let checkInKey = "dailyCheckIns"
    private let streakKey = "currentStreak"
    private let taskStreakKey = "taskCompletionStreak"
    
    @Published var dailyRecords: [String: DailyRecord] = [:]
    @Published var currentStreak: Int = 0 // App open streak
    @Published var taskCompletionStreak: Int = 0 // Daily task completion streak (read + pray)
    @Published var hasPrayedToday: Bool = false
    @Published var hasReadToday: Bool = false
    
    private init() {
        loadData()
        recordAppOpen()
    }
    
    // MARK: - Public Actions
    
    func recordAppOpen() {
        let today = formatDate(Date())
        updateRecord(date: today, type: .appOpen)
        updateStreak()
        // Use immediate sync to ensure widget gets fresh streak data on app open
        Task { @MainActor in
            WidgetDataSync.shared.syncToWidgetImmediately()
        }
    }
    
    func recordPrayer() {
        let today = formatDate(Date())
        updateRecord(date: today, type: .prayer)
        hasPrayedToday = true
        updateStreak() // Update app open streak
        updateTaskStreak() // Update task completion streak
        
        // Cancel evening prayer reminder since user already prayed
        NotificationManager.shared.cancelPrayerReminder()
        syncToWidget()
    }
    
    func recordReading() {
        let today = formatDate(Date())
        // Only record once per day
        if let record = dailyRecords[today], record.hasReadToday {
            return // Already recorded today
        }
        updateRecord(date: today, type: .reading)
        hasReadToday = true
        updateTaskStreak() // Update task completion streak
        syncToWidget()
    }
    
    // MARK: - Widget Sync
    
    private func syncToWidget() {
        Task { @MainActor in
            WidgetDataSync.shared.syncToWidget()
        }
    }
    
    func getRecord(for date: Date) -> DailyRecord? {
        return dailyRecords[formatDate(date)]
    }
    
    // MARK: - Internal Logic
    
    private func updateRecord(date: String, type: CheckInType) {
        var record = dailyRecords[date] ?? DailyRecord(dateString: date, types: [], lastUpdated: Date())
        record.types.insert(type)
        record.lastUpdated = Date()
        
        dailyRecords[date] = record
        saveData()
        
        let today = formatDate(Date())
        if date == today {
            if type == .prayer {
                hasPrayedToday = true
            } else if type == .reading {
                hasReadToday = true
            }
        }
    }
    
    private func updateStreak() {
        // Simple streak calculation: consecutive days with at least one check-in (appOpen or prayer)
        // Prompt says "Opening the app... to continue their streak"
        
        let today = Date()
        
        // If no record today yet, streak might be from yesterday
        // But we just called recordAppOpen, so today should exist.
        
        var streak = 0
        var checkDate = today
        
        // Check today
        if dailyRecords[formatDate(checkDate)] != nil {
            streak += 1
        } else {
            // If today not done, check yesterday (shouldn't happen if called after recordAppOpen)
        }
        
        // Check previous days
        while true {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let dateStr = formatDate(yesterday)
            
            if dailyRecords[dateStr] != nil {
                streak += 1
                checkDate = yesterday
            } else {
                break
            }
        }
        
        self.currentStreak = streak
        userDefaults.set(streak, forKey: streakKey)
    }
    
    private func updateTaskStreak() {
        // Task completion streak: consecutive days with both read AND pray completed
        let today = Date()
        var streak = 0
        var checkDate = today
        
        // Check today first
        let todayStr = formatDate(checkDate)
        if let record = dailyRecords[todayStr], record.hasCompletedDailyTasks {
            streak += 1
        } else {
            // If today not completed, streak is 0 (can't have a streak without today)
            self.taskCompletionStreak = 0
            userDefaults.set(0, forKey: taskStreakKey)
            return
        }
        
        // Check previous days
        while true {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let dateStr = formatDate(yesterday)
            
            if let record = dailyRecords[dateStr], record.hasCompletedDailyTasks {
                streak += 1
                checkDate = yesterday
            } else {
                break
            }
        }
        
        self.taskCompletionStreak = streak
        userDefaults.set(streak, forKey: taskStreakKey)
    }
    
    private func loadData() {
        if let data = userDefaults.data(forKey: checkInKey),
           let records = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.dailyRecords = records
        }
        
        // Check if prayed and read today
        let today = formatDate(Date())
        if let record = dailyRecords[today] {
            self.hasPrayedToday = record.hasPrayed
            self.hasReadToday = record.hasReadToday
        } else {
            self.hasPrayedToday = false
            self.hasReadToday = false
        }
        
        // Load task completion streak
        self.taskCompletionStreak = userDefaults.integer(forKey: taskStreakKey)
        
        // Recalculate task streak from loaded data to ensure accuracy
        let todayDate = Date()
        var taskStreak = 0
        var checkDate = todayDate
        
        // Check today
        let todayStr = formatDate(checkDate)
        if let record = dailyRecords[todayStr], record.hasCompletedDailyTasks {
            taskStreak += 1
        }
        
        // Check previous days
        while true {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let dateStr = formatDate(yesterday)
            
            if let record = dailyRecords[dateStr], record.hasCompletedDailyTasks {
                taskStreak += 1
                checkDate = yesterday
            } else {
                break
            }
        }
        
        self.taskCompletionStreak = taskStreak
        
        // Recalculate app open streak from loaded data to ensure accuracy
        // (Don't call updateStreak() here as it will save, and we haven't recorded today's app open yet)
        // Instead, calculate manually
        var streak = 0
        checkDate = todayDate // Reuse checkDate from above
        
        // Check today
        if dailyRecords[formatDate(checkDate)] != nil {
            streak += 1
        }
        
        // Check previous days
        while true {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let dateStr = formatDate(yesterday)
            
            if dailyRecords[dateStr] != nil {
                streak += 1
                checkDate = yesterday
            } else {
                break
            }
        }
        
        self.currentStreak = streak
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(dailyRecords) {
            userDefaults.set(encoded, forKey: checkInKey)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
