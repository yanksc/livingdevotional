// CheckInCard.swift
// Component for Daily Check-in on Home Screen

import SwiftUI

struct CheckInCard: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var showEncouragement = false
    @State private var calendarViewMode: CalendarViewMode = .week
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title & View Toggle
            HStack {
                Text(settingsStore.appLanguage == .chineseTraditional ? "每日簽到" : "Daily Check-in")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
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
            
            // Calendar View with Streak & Prayer Status
            CheckInCalendarView(
                checkInStore: checkInStore,
                viewMode: calendarViewMode,
                showPrayerStatus: true
            )
            .padding(.vertical, 4)
            
            // Prayer Check-in Prompt (only if not prayed)
            if !checkInStore.hasPrayedToday {
                VStack(alignment: .leading, spacing: 12) {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "您今天禱告了嗎？" : "Have you prayed today?")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    HStack(spacing: 12) {
                        // Yes Button
                        Button {
                            withAnimation {
                                checkInStore.recordPrayer()
                            }
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "有的" : "Yes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AppTheme.accentColor)
                                .cornerRadius(8)
                        }
                        
                        // No Button
                        Button {
                            showEncouragement = true
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "還沒" : "Not yet")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AppTheme.secondaryText.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showEncouragement) {
            PrayerEncouragementView(onPrayNow: {
                withAnimation {
                    checkInStore.recordPrayer()
                }
            })
            .presentationDetents([.large])
        }
    }
}
