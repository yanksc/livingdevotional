// CheckInCard.swift
// Component for Daily Check-in on Home Screen

import SwiftUI

struct CheckInCard: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    var onPrayNow: () -> Void
    @State private var calendarViewMode: CalendarViewMode = .week
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title & View Toggle
            HStack {
                Text(settingsStore.appLanguage == .chineseTraditional ? "每日簽到" : "Daily Check-in")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                // Dual Streak Info
                HStack(spacing: 12) {
                    // App Open Streak
                    HStack(spacing: 4) {
                        LatinCrossView(size: 12, lineWidth: 1.5, color: AppTheme.accentColor)
                        Text("\(checkInStore.currentStreak)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentColor)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "天" : "d")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    // Task Completion Streak
                    if checkInStore.taskCompletionStreak > 0 {
                        HStack(spacing: 4) {
                            // Circle with border to match calendar visual
                            ZStack {
                                Circle()
                                    .stroke(Color.purple, lineWidth: 2)
                                    .frame(width: 14, height: 14)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            Text("\(checkInStore.taskCompletionStreak)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "天" : "d")
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.trailing, 8)
                
                // Small Week/Month Toggle
                HStack(spacing: 4) {
                    Button {
                        withAnimation {
                            calendarViewMode = .week
                        }
                    } label: {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "週" : "W")
                            .font(.caption2)
                            .fontWeight(calendarViewMode == .week ? .bold : .regular)
                            .foregroundColor(calendarViewMode == .week ? AppTheme.accentColor : AppTheme.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(calendarViewMode == .week ? AppTheme.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                    }
                    
                    Button {
                        withAnimation {
                            calendarViewMode = .month
                        }
                    } label: {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "月" : "M")
                            .font(.caption2)
                            .fontWeight(calendarViewMode == .month ? .bold : .regular)
                            .foregroundColor(calendarViewMode == .month ? AppTheme.accentColor : AppTheme.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(calendarViewMode == .month ? AppTheme.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                    }
                }
            }
            
            // Calendar View
            CheckInCalendarView(
                checkInStore: checkInStore,
                viewMode: calendarViewMode,
                showPrayerStatus: true
            )
            .padding(.vertical, 4)
            
            // Prayer prompt (only when user has not prayed today)
            if !checkInStore.hasPrayedToday {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            checkInStore.recordPrayer()
                        }
                    } label: {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "已禱告" : "Prayed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(AppTheme.accentColor)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onPrayNow()
                    } label: {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "現在禱告" : "Pray Now")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(AppTheme.secondaryText.opacity(0.1))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
