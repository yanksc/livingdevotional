// MyRecordsSheet - Half-sheet with 2x2 grid of record categories
// Opened from the Journey tab's nav bar to access history, notes, Q&A, and prayers

import SwiftUI

struct MyRecordsSheet: View {
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @ObservedObject private var prayerLogStore = PrayerLogStore.shared
    @EnvironmentObject var router: AppRouter
    
    @State private var showReadingHistory = false
    @State private var showSavedNotes = false
    @State private var showChatHistory = false
    @State private var showPrayerHistory = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        RecordCard(
                            icon: "clock.arrow.circlepath",
                            title: settingsStore.appLanguage.localizedString("ReadingHistory"),
                            count: progressStore.readingHistory.count,
                            countSuffix: countSuffix(for: "chapters")
                        ) {
                            showReadingHistory = true
                        }
                        
                        RecordCard(
                            icon: "bookmark.fill",
                            title: settingsStore.appLanguage.localizedString("MyNotes"),
                            count: noteStore.savedVerses.count,
                            countSuffix: countSuffix(for: "saved")
                        ) {
                            showSavedNotes = true
                        }
                        
                        RecordCard(
                            icon: "bubble.left.and.bubble.right",
                            title: settingsStore.appLanguage.localizedString("QAHistory"),
                            count: chatStore.sessions.count,
                            countSuffix: countSuffix(for: "conversations")
                        ) {
                            showChatHistory = true
                        }
                        
                        RecordCard(
                            icon: "hands.sparkles.fill",
                            title: settingsStore.appLanguage.localizedString("PrayerRecords"),
                            count: prayerLogStore.logs.count,
                            countSuffix: countSuffix(for: "prayers")
                        ) {
                            showPrayerHistory = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationTitle(settingsStore.appLanguage.localizedString("MyRecords"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showReadingHistory) {
                NavigationStack {
                    ReadingHistoryView()
                        .environmentObject(router)
                }
            }
            .sheet(isPresented: $showSavedNotes) {
                NavigationStack {
                    SavedNotesListView(
                        noteStore: noteStore,
                        settingsStore: settingsStore
                    )
                    .environmentObject(router)
                }
            }
            .sheet(isPresented: $showChatHistory) {
                NavigationStack {
                    ChatHistoryView()
                        .environmentObject(router)
                }
            }
            .sheet(isPresented: $showPrayerHistory) {
                NavigationStack {
                    PrayerHistoryView()
                        .environmentObject(router)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func countSuffix(for type: String) -> String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        let isSpanish = settingsStore.appLanguage == .spanish
        let isPortuguese = settingsStore.appLanguage == .portuguese
        
        switch type {
        case "chapters":
            if isChinese { return "章" }
            if isSpanish { return "capítulos" }
            if isPortuguese { return "capítulos" }
            return "chapters"
        case "saved":
            if isChinese { return "條" }
            if isSpanish { return "guardados" }
            if isPortuguese { return "salvos" }
            return "saved"
        case "conversations":
            if isChinese { return "次" }
            if isSpanish { return "conversaciones" }
            if isPortuguese { return "conversas" }
            return "conversations"
        case "prayers":
            if isChinese { return "次" }
            if isSpanish { return "oraciones" }
            if isPortuguese { return "orações" }
            return "prayers"
        default:
            return ""
        }
    }
}

// MARK: - Record Card

struct RecordCard: View {
    let icon: String
    let title: String
    let count: Int
    let countSuffix: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // Count
                Text("\(count) \(countSuffix)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(AppTheme.cardGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
