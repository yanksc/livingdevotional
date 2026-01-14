// CheckInStore - Manages daily check-ins and streaks
//
// Tracks:
// 1. App Open (automatic)
// 2. Prayer Check-in (manual)
//

import Foundation
import Combine

enum CheckInType: String, Codable {
    case appOpen
    case prayer
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
    
    @Published var dailyRecords: [String: DailyRecord] = [:]
    @Published var currentStreak: Int = 0
    @Published var hasPrayedToday: Bool = false
    
    private init() {
        loadData()
        recordAppOpen()
    }
    
    // MARK: - Public Actions
    
    func recordAppOpen() {
        let today = formatDate(Date())
        updateRecord(date: today, type: .appOpen)
        updateStreak()
    }
    
    func recordPrayer() {
        let today = formatDate(Date())
        updateRecord(date: today, type: .prayer)
        hasPrayedToday = true
        updateStreak() // Update streak when prayer is recorded
        
        // Cancel evening prayer reminder since user already prayed
        NotificationManager.shared.cancelPrayerReminder()
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
        
        if date == formatDate(Date()) && type == .prayer {
            hasPrayedToday = true
        }
    }
    
    private func updateStreak() {
        // Simple streak calculation: consecutive days with at least one check-in (appOpen or prayer)
        // Prompt says "Opening the app... to continue their streak"
        
        let today = Date()
        let todayStr = formatDate(today)
        
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
    
    private func loadData() {
        if let data = userDefaults.data(forKey: checkInKey),
           let records = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            self.dailyRecords = records
        }
        
        // Check if prayed today
        let today = formatDate(Date())
        if let record = dailyRecords[today] {
            self.hasPrayedToday = record.hasPrayed
        } else {
            self.hasPrayedToday = false
        }
        
        // Recalculate streak from loaded data to ensure accuracy
        // (Don't call updateStreak() here as it will save, and we haven't recorded today's app open yet)
        // Instead, calculate manually
        let todayDate = Date()
        var streak = 0
        var checkDate = todayDate
        
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
