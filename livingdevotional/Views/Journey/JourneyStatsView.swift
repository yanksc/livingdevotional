// JourneyStatsView.swift
// Stats display views for the Journey feature

import SwiftUI

// MARK: - Stats View

struct JourneyStatsView: View {
    let stats: JourneyStats
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "章節" : "Chapters",
                value: "\(stats.totalChaptersRead)",
                icon: "book.fill"
            )
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "保存" : "Saved",
                value: "\(stats.totalVersesSaved)",
                icon: "bookmark.fill"
            )
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "連續" : "Streak",
                value: "\(stats.currentStreak)",
                icon: "cross.fill"
            )
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
