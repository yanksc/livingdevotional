// ReadingHistoryView - Displays reading history grouped by date

import SwiftUI

struct ReadingHistoryView: View {
    @ObservedObject var progressStore = ProgressStore.shared
    @ObservedObject var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var groupedHistory: [String: [ReadingHistoryItem]] = [:]
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if progressStore.readingHistory.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
        .navigationTitle(settingsStore.appLanguage.localizedString("ReadingHistory"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateGroupedHistory()
        }
        .onChange(of: progressStore.readingHistory) { _, _ in
            updateGroupedHistory()
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(settingsStore.appLanguage.localizedString("NoReadingHistory"))
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
            
            Text(settingsStore.appLanguage.localizedString("ReadingHistoryEmptyMessage"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedSectionKeys, id: \.self) { sectionKey in
                    if let items = groupedHistory[sectionKey] {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section header
                            Text(sectionKey)
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Items in section
                            ForEach(items) { item in
                                HistoryItemRow(
                                    item: item,
                                    settingsStore: settingsStore,
                                    router: router,
                                    onNavigate: {
                                        dismiss()
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Helpers
    
    private var sortedSectionKeys: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        return groupedHistory.keys.sorted { key1, key2 in
            // Today first
            if key1 == localizedDateKey(today) { return true }
            if key2 == localizedDateKey(today) { return false }
            
            // Yesterday second
            if key1 == localizedDateKey(yesterday) { return true }
            if key2 == localizedDateKey(yesterday) { return false }
            
            // Then by date (newest first)
            if let date1 = dateFromKey(key1), let date2 = dateFromKey(key2) {
                return date1 > date2
            }
            
            return key1 > key2
        }
    }
    
    private func updateGroupedHistory() {
        let calendar = Calendar.current
        var grouped: [String: [ReadingHistoryItem]] = [:]
        
        for item in progressStore.readingHistory {
            let dateKey = localizedDateKey(item.timestamp)
            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(item)
        }
        
        // Sort items within each group by timestamp (newest first)
        for key in grouped.keys {
            grouped[key]?.sort { $0.timestamp > $1.timestamp }
        }
        
        groupedHistory = grouped
    }
    
    private func localizedDateKey(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let itemDate = calendar.startOfDay(for: date)
        
        let isChinese = settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant"
        
        if calendar.isDateInToday(itemDate) {
            return isChinese ? "今天" : "Today"
        } else if calendar.isDate(itemDate, inSameDayAs: yesterday) {
            return isChinese ? "昨天" : "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: itemDate)?.contains(today) ?? false {
            // This week
            let formatter = DateFormatter()
            formatter.dateFormat = isChinese ? "EEEE" : "EEEE"
            formatter.locale = Locale(identifier: isChinese ? "zh_Hant_TW" : "en_US")
            return formatter.string(from: itemDate)
        } else {
            // Older dates
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.string(from: itemDate)
        }
    }
    
    private func dateFromKey(_ key: String) -> Date? {
        let isChinese = settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant"
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        if key == (isChinese ? "今天" : "Today") {
            return today
        } else if key == (isChinese ? "昨天" : "Yesterday") {
            return yesterday
        } else {
            // Try to parse as date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.date(from: key)
        }
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: ReadingHistoryItem
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    let onNavigate: () -> Void
    
    var body: some View {
        Button(action: {
            navigateToChapter()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Book and chapter info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedBookChapter)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(formatTime(item.timestamp))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            }
            .padding(16)
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = settingsStore.appLanguage.resolvedLocale()
        return formatter.string(from: date)
    }
    
    private func navigateToChapter() {
        if let book = BibleData.book(named: item.book) {
            router.navigateToReading(book: book, chapter: item.chapter, verse: nil)
            onNavigate()
        }
    }
}

#Preview {
    NavigationStack {
        ReadingHistoryView()
            .environmentObject(AppRouter())
    }
}
