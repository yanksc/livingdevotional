// JourneyWidgetViews.swift
// Widget-style views for the Journey feature: timeline

import SwiftUI

// MARK: - Timeline Widget View

struct TimelineWidgetView: View {
    let milestones: [JourneyMilestone]
    let isLoading: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "活動時間軸" : "Activity Timeline")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if !milestones.isEmpty {
                    Text("\(milestones.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.sectionBackground)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            // Small Timeline Preview
            if isLoading && milestones.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if milestones.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "開始您的旅程！" : "Start your journey!")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Show compact timeline preview (first 3-4 items)
                VStack(spacing: 8) {
                    ForEach(Array(milestones.prefix(4))) { milestone in
                        TimelineItemRow(milestone: milestone)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Timeline Item Row

struct TimelineItemRow: View {
    let milestone: JourneyMilestone
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: milestone.iconName)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text(formatDate(milestone.date))
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let isChinese = settingsStore.appLanguage == .chineseTraditional
        
        if calendar.isDateInToday(date) {
            return isChinese ? "今天" : "Today"
        } else if calendar.isDateInYesterday(date) {
            return isChinese ? "昨天" : "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.string(from: date)
        }
    }
}

// NOTE: RecentHistoryWidgetView, RecentHistoryCard, MyNotesWidgetView, and NoteCard
// have been removed. History records are now accessed via MyRecordsSheet from the
// Journey tab's nav bar (archivebox icon), which opens the full list views directly.
