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
            let hasAppOpen = record?.hasOpenedApp ?? false
            let hasTaskCompletion = record?.hasCompletedDailyTasks ?? false
            let isToday = calendar.isDateInToday(date)
            
            // Calculate app open streak position
            var appOpenStreakPosition = 0
            if hasAppOpen {
                var checkDate = today
                var position = checkInStore.currentStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        appOpenStreakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr]?.hasOpenedApp ?? false {
                        position -= 1
                    } else {
                        break
                    }
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                }
            }
            
            // Calculate task completion streak position
            var taskStreakPosition = 0
            if hasTaskCompletion {
                var checkDate = today
                var position = checkInStore.taskCompletionStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        taskStreakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr]?.hasCompletedDailyTasks ?? false {
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
                streakPosition: appOpenStreakPosition, // Keep for backward compatibility
                isToday: isToday,
                hasAppOpen: hasAppOpen,
                hasTaskCompletion: hasTaskCompletion,
                appOpenStreakPosition: appOpenStreakPosition,
                taskStreakPosition: taskStreakPosition
            ))
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Week Grid - Condensed Visual Design
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.date) { day in
                    VStack(spacing: 4) {
                        // Visual indicator - dual streaks
                        ZStack {
                            // Background circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: day.hasTaskCompletion 
                                            ? [Color.purple.opacity(0.2), Color.purple.opacity(0.1)]
                                            : day.hasAppOpen
                                            ? [Color.orange.opacity(0.2), Color.orange.opacity(0.1)]
                                            : [AppTheme.secondaryText.opacity(0.1), AppTheme.secondaryText.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            // Task completion indicator (extra border ring)
                            if day.hasTaskCompletion {
                                Circle()
                                    .stroke(Color.purple, lineWidth: 2.5)
                                    .frame(width: 32, height: 32)
                            }
                            
                            // App open streak indicator (flame) - centered
                            if day.hasAppOpen {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: day.appOpenStreakPosition > 0 ? 14 : 12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            // Task completion only (no app open) - show checkmark
                            if day.hasTaskCompletion && !day.hasAppOpen {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            
                            // Empty state indicator
                            if !day.hasAppOpen && !day.hasTaskCompletion {
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
        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else {
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
            let hasAppOpen = record?.hasOpenedApp ?? false
            let hasTaskCompletion = record?.hasCompletedDailyTasks ?? false
            let isToday = calendar.isDateInToday(date)
            
            // Calculate app open streak position
            var appOpenStreakPosition = 0
            if hasAppOpen {
                var checkDate = today
                var position = checkInStore.currentStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        appOpenStreakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr]?.hasOpenedApp ?? false {
                        position -= 1
                    } else {
                        break
                    }
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                }
            }
            
            // Calculate task completion streak position
            var taskStreakPosition = 0
            if hasTaskCompletion {
                var checkDate = today
                var position = checkInStore.taskCompletionStreak
                
                while position > 0 {
                    let checkDateStr = formatDate(checkDate)
                    if checkDateStr == dateStr {
                        taskStreakPosition = position
                        break
                    }
                    if checkInStore.dailyRecords[checkDateStr]?.hasCompletedDailyTasks ?? false {
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
                streakPosition: appOpenStreakPosition, // Keep for backward compatibility
                isToday: isToday,
                hasAppOpen: hasAppOpen,
                hasTaskCompletion: hasTaskCompletion,
                appOpenStreakPosition: appOpenStreakPosition,
                taskStreakPosition: taskStreakPosition
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
        let data = monthData
        
        return VStack(spacing: 16) {
            monthHeader(data: data)
            weekdayHeaders
            calendarGrid(data: data)
        }
    }
    
    private func monthHeader(data: MonthData) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppTheme.accentColor)
                .font(.subheadline)
            Text(data.monthName)
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
        }
    }
    
    private var weekdayHeaders: some View {
        HStack(spacing: 4) {
            ForEach(weekDayNames, id: \.self) { name in
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func calendarGrid(data: MonthData) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(Array(data.days.enumerated()), id: \.offset) { index, dayData in
                dayCell(dayData: dayData)
            }
        }
    }
    
    @ViewBuilder
    private func dayCell(dayData: MonthDayData?) -> some View {
        if let day = dayData {
            VStack(spacing: 4) {
                Text("\(day.day)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(day.isToday ? AppTheme.accentColor : AppTheme.primaryText)
                
                streakIndicators(day: day)
                streakPositionNumbers(day: day)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(4)
            .background(dayBackground(day: day))
            .overlay(dayBorder(day: day))
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }
    
    @ViewBuilder
    private func streakIndicators(day: MonthDayData) -> some View {
        ZStack {
            // Task completion indicator (extra border ring)
            if day.hasTaskCompletion {
                Circle()
                    .stroke(Color.purple, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
            
            // App open indicator (flame) - centered
            if day.hasAppOpen {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            
            // Task completion only (no app open) - show checkmark
            if day.hasTaskCompletion && !day.hasAppOpen {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.purple)
            }
            
            // Empty state indicator
            if !day.hasAppOpen && !day.hasTaskCompletion {
                Circle()
                    .stroke(AppTheme.secondaryText.opacity(0.1), lineWidth: 1)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 20, height: 20)
    }
    
    @ViewBuilder
    private func streakPositionNumbers(day: MonthDayData) -> some View {
        if day.appOpenStreakPosition > 0 || day.taskStreakPosition > 0 {
            HStack(spacing: 2) {
                if day.appOpenStreakPosition > 0 {
                    Text("#\(day.appOpenStreakPosition)")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.orange)
                }
                if day.taskStreakPosition > 0 {
                    Text("#\(day.taskStreakPosition)")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    private func dayBackground(day: MonthDayData) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(day.isToday ? AppTheme.accentColor.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(day.isToday ? AppTheme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
    
    private func dayBorder(day: MonthDayData) -> some View {
        let borderColor: Color = {
            if day.hasTaskCompletion {
                return Color.purple.opacity(0.3)
            } else if day.hasAppOpen {
                return Color.orange.opacity(0.3)
            } else {
                return Color.clear
            }
        }()
        
        return RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: 1.5)
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
    let hasAppOpen: Bool
    let hasTaskCompletion: Bool
    let appOpenStreakPosition: Int
    let taskStreakPosition: Int
}

struct MonthDayData {
    let day: Int
    let date: String
    let hasCheckIn: Bool
    let streakPosition: Int
    let isToday: Bool
    let hasAppOpen: Bool
    let hasTaskCompletion: Bool
    let appOpenStreakPosition: Int
    let taskStreakPosition: Int
}

struct MonthData {
    let days: [MonthDayData?]
    let monthName: String
}
