// HomeView - Main home screen

import SwiftUI

struct HomeView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var bibleViewModel: BibleViewModel
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var checkInStore = CheckInStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var showSavedNotes = false
    @State private var showChatHistory = false
    @State private var showPrayerFlow = false
    @State private var showVerseSearch = false
    @State private var showReadingHistory = false
    @State private var showJourney = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Verse of the day
                    verseOfTheDaySection
                    
                    // Daily Check-in
                    CheckInCard(checkInStore: checkInStore)
                    
                    // Journey Card
                    JourneyCard(showJourney: $showJourney)
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent history
                    recentHistorySection
                    
                    // Saved notes preview
                    savedNotesPreviewSection
                }
                .padding()
                .padding(.bottom, 100) // Extra padding for tab bar
            }
        }
        .navigationTitle(settingsStore.appLanguage.localizedString("Home"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            viewModel.loadHomeData()
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
        .fullScreenCover(isPresented: $showPrayerFlow) {
            PrayerFlowView()
        }
        .sheet(isPresented: $showVerseSearch) {
            VerseSearchView(settingsStore: settingsStore)
                .environmentObject(router)
        }
        .sheet(isPresented: $showReadingHistory) {
            NavigationStack {
                ReadingHistoryView()
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showJourney) {
            JourneyView()
        }
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Living Path")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.accentColor)
            Text(settingsStore.appLanguage.localizedString("WelcomeSubtitle"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var verseOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settingsStore.appLanguage.localizedString("VerseOfTheDay"))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if let verse = viewModel.verseOfTheDay {
                    ShareLink(item: formatVerseForShare(verse)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            
            if let verse = viewModel.verseOfTheDay {
                VStack(alignment: .leading, spacing: 16) {
                    // Verse text
                    VStack(alignment: .leading, spacing: 12) {
                        Text(verse.text(for: settingsStore.primaryLanguage))
                            .font(settingsStore.selectedFont.font(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                        
                        if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                            Text(verse.text(for: settingsStore.secondaryLanguage))
                                .font(settingsStore.selectedFont.font(size: 16))
                                .foregroundColor(AppTheme.secondaryText)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Divider()
                        .overlay(AppTheme.accentColor.opacity(0.2))
                    
                    // Reference
                    HStack {
                        Text(localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.accentColor)
                        
                        Spacer()
                        
                        Button {
                            // Navigate to this verse
                            if let book = BibleData.book(named: verse.book) {
                                router.navigateToReading(book: book, chapter: verse.chapter, verse: verse.verseNumber)
                            }
                        } label: {
                            Text(settingsStore.appLanguage.localizedString("ReadChapter"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accentColor.opacity(0.1))
                                .foregroundColor(AppTheme.accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background(
                    ZStack {
                        AppTheme.cardGradient
                        
                        // Subtle background decoration
                        GeometryReader { proxy in
                            Image(systemName: "quote.opening")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.accentColor.opacity(0.05))
                                .position(x: 40, y: 40)
                        }
                    }
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(16)
            } else {
                Text(settingsStore.appLanguage.localizedString("UnableToLoadVerse"))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage.localizedString("QuickActions"))
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickActionButton(title: settingsStore.appLanguage.localizedString("Pray"), icon: "hands.sparkles.fill", color: AppTheme.accentColor) {
                        showPrayerFlow = true
                    }
                    
                    quickActionButton(title: settingsStore.appLanguage.localizedString("FindVerse"), icon: "magnifyingglass", color: AppTheme.primaryPurple) {
                        showVerseSearch = true
                    }
                }
                
                HStack(spacing: 12) {
                    quickActionButton(title: settingsStore.appLanguage.localizedString("MyNotes"), icon: "bookmark.fill", color: AppTheme.accentColor) {
                        showSavedNotes = true
                    }
                    
                    quickActionButton(title: settingsStore.appLanguage.localizedString("QAHistory"), icon: "bubble.left.and.bubble.right.fill", color: AppTheme.primaryPurple) {
                        showChatHistory = true
                    }
                }
            }
        }
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(height: 28)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Helpers
    
    private func localizedReference(book: String, chapter: Int, verse: Int) -> String {
        // Use primaryLanguage for book/chapter references
        let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(chapter):\(verse)"
    }
    
    private func formatVerseForShare(_ verse: DailyVerse) -> String {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Path"
    }
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settingsStore.appLanguage.localizedString("RecentHistory"))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button(settingsStore.appLanguage.localizedString("ViewAll")) {
                    showReadingHistory = true
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.accentColor)
            }
            
            let recentItems = progressStore.getRecentHistory(limit: 3)
            
            if recentItems.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.secondaryText)
                    Text(settingsStore.appLanguage.localizedString("NoReadingHistory"))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentItems) { item in
                        HistoryPreviewRow(item: item, settingsStore: settingsStore, router: router)
                    }
                }
            }
        }
    }
    
    private var savedNotesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settingsStore.appLanguage.localizedString("SavedNotes"))
                    .font(AppFont.serif.font(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button(settingsStore.appLanguage.localizedString("ViewAll")) {
                    showSavedNotes = true
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.accentColor)
            }
            
            if noteStore.savedVerses.isEmpty {
                Text(settingsStore.appLanguage.localizedString("NoSavedVerses"))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(noteStore.savedVerses.prefix(3)), id: \.id) { savedVerse in
                        SavedNotePreviewRow(savedVerse: savedVerse)
                    }
                    
                    if noteStore.savedVerses.count > 3 {
                        Button(action: {
                            showSavedNotes = true
                        }) {
                            Text(viewMoreText(count: noteStore.savedVerses.count - 3))
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
    
    private func viewMoreText(count: Int) -> String {
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        if languageCode == "zh-Hans" {
            return "查看其他 \(count) 项..."
        } else if languageCode == "zh-Hant" {
            return "查看其他 \(count) 項..."
        } else {
            return "View \(count) more..."
        }
    }
}

// MARK: - Saved Note Preview Row

struct SavedNotePreviewRow: View {
    let savedVerse: SavedVerse
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToVerse()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedVerseReference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    if !savedVerse.content.isEmpty {
                        Text(savedVerse.content)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            }
            .padding()
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var localizedVerseReference: String {
        // Get localized book name based on primary language
        let localizedBook = BibleData.localizedBookName(savedVerse.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
    }
    
    private func navigateToVerse() {
        // Convert book string to BibleBook object
        if let book = BibleData.book(named: savedVerse.book) {
                router.navigateToReading(book: book, chapter: savedVerse.chapter, verse: savedVerse.verse)
        }
    }
}

// MARK: - History Preview Row

struct HistoryPreviewRow: View {
    let item: ReadingHistoryItem
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToChapter()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedBookChapter)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(formatTime(item.timestamp))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            }
            .padding()
            .background(AppTheme.cardGradient)
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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = settingsStore.appLanguage.resolvedLocale()
        return formatter.string(from: date)
    }
    
    private func navigateToChapter() {
        if let book = BibleData.book(named: item.book) {
            router.navigateToReading(book: book, chapter: item.chapter, verse: nil)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppRouter())
            .environmentObject(BibleViewModel())
    }
}
