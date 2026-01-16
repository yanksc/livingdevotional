// PrayerHistoryView.swift
// Displays list of prayer logs

import SwiftUI

struct PrayerHistoryView: View {
    @ObservedObject private var prayerLogStore = PrayerLogStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if prayerLogStore.logs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor.opacity(0.5))
                    
                    Text(settingsStore.appLanguage == .chineseTraditional ? "尚無禱告記錄" : "No Prayer Records")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(settingsStore.appLanguage == .chineseTraditional ? "您的禱告記錄將顯示在這裡" : "Your prayer records will appear here")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(prayerLogStore.logs) { log in
                            PrayerLogRow(log: log)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "禱告記錄" : "Prayer Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct PrayerLogRow: View {
    let log: PrayerLog
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var isExpanded = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    // Topic and date
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topicDisplay)
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                        
                        Text(formatDate(log.date))
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Verse reference
                Text(log.verseReference)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.accentColor)
                
                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        // Verse text
                        Text("\"\(log.verseText)\"")
                            .font(.body)
                            .italic()
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(4)
                        
                        Divider()
                            .overlay(AppTheme.accentColor.opacity(0.2))
                        
                        // Prayer text preview
                        Text(log.prayerText)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(6)
                            .lineLimit(10)
                        
                        // Emotional need if available
                        if let need = log.emotionalNeed {
                            HStack {
                                Text(settingsStore.appLanguage == .chineseTraditional ? "需要：" : "Need:")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                Text(need.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button {
                                navigateToVerse()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "book.fill")
                                        .font(.caption)
                                    Text(settingsStore.appLanguage == .chineseTraditional ? "閱讀經文" : "Read Verse")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.accentColor)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(AppTheme.cardGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var topicDisplay: String {
        if log.topic == "custom", let customText = log.customTopicText {
            return customText
        } else {
            // Map topic to display name
            let isChinese = settingsStore.appLanguage == .chineseTraditional
            switch log.topic {
            case "recent_focus":
                return isChinese ? "最近的關注" : "Recent focus"
            case "worry":
                return isChinese ? "擔憂焦慮" : "Worry/anxiety"
            case "gratitude":
                return isChinese ? "感恩感謝" : "Gratitude/thanksgiving"
            case "guidance":
                return isChinese ? "指引決定" : "Guidance/decision"
            case "strength":
                return isChinese ? "力量鼓勵" : "Strength/encouragement"
            case "other":
                return isChinese ? "其他" : "Other"
            default:
                return log.topic.capitalized
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = settingsStore.appLanguage.resolvedLocale()
        return formatter.string(from: date)
    }
    
    private func navigateToVerse() {
        if let book = BibleData.book(named: log.verseBook) {
            router.navigateToReading(book: book, chapter: log.verseChapter, verse: log.verseNumber)
        }
    }
}

#Preview {
    NavigationStack {
        PrayerHistoryView()
            .environmentObject(AppRouter())
    }
}
