// CheckInCalendarView.swift
// Calendar component showing 7-day week view and monthly calendar

import SwiftUI

enum CalendarViewMode: String, CaseIterable {
    case week
    case month
}

struct CheckInCalendarView: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    var viewMode: CalendarViewMode
    var showPrayerStatus: Bool = false
    
    var body: some View {
        if viewMode == .week {
            WeekCalendarView(checkInStore: checkInStore, showPrayerStatus: showPrayerStatus)
        } else {
            MonthCalendarView(checkInStore: checkInStore)
        }
    }
}

// MARK: - Week View (7 days)

struct WeekCalendarView: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    var showPrayerStatus: Bool = false
    
    private var weekDays: [WeekDayData] {
        let today = Date()
        let calendar = Calendar.current
        var days: [WeekDayData] = []
        
        // Get last 7 days (including today)
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let dateStr = formatDate(date)
            let record = checkInStore.dailyRecords[dateStr]
            let hasCheckIn = record != nil
            let isToday = calendar.isDateInToday(date)
            
            // Calculate streak position (counting backwards from today)
            var streakPosition = 0
            if hasCheckIn {
                var checkDate = today
                var position = checkInStore.currentStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        streakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr] != nil {
                        position -= 1
                    } else {
                        break
                    }
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                }
            }
            
            let dayName = formatDayName(date)
            let dayNum = calendar.component(.day, from: date)
            
            days.append(WeekDayData(
                date: dateStr,
                dayName: dayName,
                dayNum: dayNum,
                hasCheckIn: hasCheckIn,
                streakPosition: streakPosition,
                isToday: isToday
            ))
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Streak Display - Compact with Prayer Status
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("\(checkInStore.currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text(settingsStore.appLanguage == .chineseTraditional ? "天連續" : "days")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                Spacer()
                
                // Prayer Status (small, on the right)
                if showPrayerStatus && checkInStore.hasPrayedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "已禱告" : "Prayed")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 4)
            
            // Week Grid - Condensed Visual Design
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.date) { day in
                    VStack(spacing: 4) {
                        // Visual indicator - filled circle for check-in, empty for missed
                        ZStack {
                            // Background circle with gradient
                            if day.hasCheckIn {
                                if day.streakPosition > 0 {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                }
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.secondaryText.opacity(0.1), AppTheme.secondaryText.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                            }
                            
                            // Check-in indicator
                            if day.hasCheckIn {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(day.streakPosition > 0 ? .orange : .green)
                            } else {
                                Circle()
                                    .stroke(AppTheme.secondaryText.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                            }
                            
                            // Today indicator ring
                            if day.isToday {
                                Circle()
                                    .stroke(AppTheme.accentColor, lineWidth: 2)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        
                        // Day number - only show for today and recent days
                        if day.isToday || day.hasCheckIn {
                            Text("\(day.dayNum)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(day.isToday ? AppTheme.accentColor : AppTheme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        if settingsStore.appLanguage == .chineseTraditional {
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "E"
        } else {
            formatter.locale = Locale(identifier: "en")
            formatter.dateFormat = "EEE"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Month View

struct MonthCalendarView: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    private var monthData: MonthData {
        let today = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        
        // First day of month
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return MonthData(days: [], monthName: "")
        }
        
        // Starting day of week (0 = Sunday)
        let startingDayOfWeek = calendar.component(.weekday, from: firstDay) - 1
        
        // Days in month
        guard let range = calendar.range(of: .day, in: .month, for: firstDay),
              let lastDay = calendar.date(byAdding: .day, value: range.count - 1, to: firstDay) else {
            return MonthData(days: [], monthName: "")
        }
        
        let daysInMonth = range.count
        
        // Build array of all days
        var days: [MonthDayData?] = []
        
        // Empty cells for days before month starts
        for _ in 0..<startingDayOfWeek {
            days.append(nil)
        }
        
        // Days of the month
        for day in 1...daysInMonth {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
            let dateStr = formatDate(date)
            let record = checkInStore.dailyRecords[dateStr]
            let hasCheckIn = record != nil
            let isToday = calendar.isDateInToday(date)
            
            // Calculate streak position
            var streakPosition = 0
            if hasCheckIn {
                var checkDate = today
                var position = checkInStore.currentStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        streakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr] != nil {
                        position -= 1
                    } else {
                        break
                    }
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                }
            }
            
            days.append(MonthDayData(
                day: day,
                date: dateStr,
                hasCheckIn: hasCheckIn,
                streakPosition: streakPosition,
                isToday: isToday
            ))
        }
        
        // Month name
        let formatter = DateFormatter()
        if settingsStore.appLanguage == .chineseTraditional {
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "yyyy年M月"
        } else {
            formatter.locale = Locale(identifier: "en")
            formatter.dateFormat = "MMMM yyyy"
        }
        let monthName = formatter.string(from: today)
        
        return MonthData(days: days, monthName: monthName)
    }
    
    private var weekDayNames: [String] {
        if settingsStore.appLanguage == .chineseTraditional {
            return ["日", "一", "二", "三", "四", "五", "六"]
        } else {
            return ["S", "M", "T", "W", "T", "F", "S"]
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Streak Display
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(checkInStore.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "天連續" : "days streak")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                Spacer()
            }
            
            // Month Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.subheadline)
                Text(monthData.monthName)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            // Weekday Headers
            HStack(spacing: 4) {
                ForEach(weekDayNames, id: \.self) { name in
                    Text(name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(monthData.days.enumerated()), id: \.offset) { index, dayData in
                    if let day = dayData {
                        VStack(spacing: 4) {
                            Text("\(day.day)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(day.isToday ? AppTheme.accentColor : AppTheme.primaryText)
                            
                            if day.hasCheckIn {
                                VStack(spacing: 1) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    
                                    if day.streakPosition > 0 {
                                        Text("#\(day.streakPosition)")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                }
                            } else {
                                Circle()
                                    .stroke(AppTheme.secondaryText.opacity(0.1), lineWidth: 1)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(day.isToday ? AppTheme.accentColor.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(day.isToday ? AppTheme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(day.hasCheckIn ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct WeekDayData {
    let date: String
    let dayName: String
    let dayNum: Int
    let hasCheckIn: Bool
    let streakPosition: Int
    let isToday: Bool
}

struct MonthDayData {
    let day: Int
    let date: String
    let hasCheckIn: Bool
    let streakPosition: Int
    let isToday: Bool
}

struct MonthData {
    let days: [MonthDayData?]
    let monthName: String
}
