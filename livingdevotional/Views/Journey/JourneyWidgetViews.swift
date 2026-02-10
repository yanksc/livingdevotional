// JourneyWidgetViews.swift
// Widget-style views for the Journey feature: timeline, recent history, and notes

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

// MARK: - Recent History Widget View

struct RecentHistoryWidgetView: View {
    let historyItems: [ReadingHistoryItem]
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "最近閱讀" : "Recent History")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Horizontal Scrollable Cards
            if historyItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "開始閱讀聖經！" : "Start reading!")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(historyItems) { item in
                            RecentHistoryCard(
                                item: item,
                                settingsStore: settingsStore,
                                router: router
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Recent History Card

struct RecentHistoryCard: View {
    let item: ReadingHistoryItem
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToChapter()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Book and chapter info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedBookChapter)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                    
                    Text(formatTime(item.timestamp))
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 140)
            .background(AppTheme.sectionBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var localizedBookChapter: String {
        let localizedBook = BibleData.localizedBookName(item.book, language: settingsStore.primaryLanguage)
        let chapterPrefix = BibleData.localizedChapterText(language: settingsStore.primaryLanguage)
        if chapterPrefix == "第" {
            return "\(localizedBook) \(chapterPrefix)\(item.chapter)章"
        } else {
            return "\(localizedBook) \(chapterPrefix) \(item.chapter)"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let isChinese = settingsStore.appLanguage == .chineseTraditional
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return isChinese ? "今天 \(formatter.string(from: date))" : "Today \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return isChinese ? "昨天" : "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.string(from: date)
        }
    }
    
    private func navigateToChapter() {
        if let book = BibleData.book(named: item.book) {
            router.navigateToReading(book: book, chapter: item.chapter, verse: nil)
        }
    }
}

// MARK: - My Notes Widget View

struct MyNotesWidgetView: View {
    let savedVerses: [SavedVerse]
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "我的筆記" : "My Notes")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Horizontal Scrollable Cards
            if savedVerses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "保存經文以在此查看！" : "Save verses to see them here!")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedVerses, id: \.id) { verse in
                            NoteCard(
                                savedVerse: verse,
                                settingsStore: settingsStore,
                                router: router
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let savedVerse: SavedVerse
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToVerse()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Verse info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedVerseReference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                    
                    if !savedVerse.content.isEmpty {
                        Text(savedVerse.content)
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                    } else {
                        Text(formatDate(savedVerse.timestamp))
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    // Labels indicator
                    if !savedVerse.labels.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.accentColor)
                            Text("\(savedVerse.labels.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentColor.opacity(0.15))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 140)
            .background(AppTheme.sectionBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var localizedVerseReference: String {
        let localizedBook = BibleData.localizedBookName(savedVerse.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = settingsStore.appLanguage.resolvedLocale()
        return formatter.string(from: date)
    }
    
    private func navigateToVerse() {
        if let book = BibleData.book(named: savedVerse.book) {
            router.navigateToReading(book: book, chapter: savedVerse.chapter, verse: savedVerse.verse)
        }
    }
}
