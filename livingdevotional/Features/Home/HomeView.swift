// HomeView - Main home screen

import SwiftUI

struct HomeView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var bibleViewModel: BibleViewModel
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @State private var showSavedNotes = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Verse of the day
                    verseOfTheDaySection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent reading
                    recentReadingSection
                    
                    // Saved notes preview
                    savedNotesPreviewSection
                }
                .padding()
                .padding(.bottom, 100) // Extra padding for tab bar
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode), for: .navigationBar)
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
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Text("Start your daily devotional journey")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var verseOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verse of the Day")
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
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                        
                        if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                            Text(verse.text(for: settingsStore.secondaryLanguage))
                                .font(.system(size: 16, weight: .regular, design: .serif))
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
                                router.navigateToReading(book: book, chapter: verse.chapter)
                            }
                        } label: {
                            Text("Read Chapter")
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
                        AppTheme.cardGradient(darkMode: settingsStore.isDarkMode)
                        
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
                    .background(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                    .cornerRadius(16)
            } else {
                Text("Unable to load verse")
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                    .cornerRadius(12)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: 12) {
                quickActionButton(title: "Read Bible", icon: "book.fill", color: AppTheme.primaryBlue) {
                    router.selectedTab = 1 // Switch to Bible tab
                }
                
                quickActionButton(title: "My Notes", icon: "bookmark.fill", color: AppTheme.accentColor) {
                    showSavedNotes = true
                }
            }
        }
    }
    
    private var recentReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Reading")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            if let recent = viewModel.recentReading,
               let book = BibleData.book(named: recent.book) {
                
                Button {
                    router.navigateToReading(book: book, chapter: recent.chapter)
                } label: {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.accentColor)
                        }
                        
                        // Text info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(BibleData.localizedBookName(recent.book, appLanguage: settingsStore.appLanguage))
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text("\(BibleData.localizedChapterText(appLanguage: settingsStore.appLanguage)) \(recent.chapter)")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(16)
                    .background(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
            } else {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(AppTheme.secondaryText)
                    Text("No recent reading")
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                .cornerRadius(12)
            }
        }
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
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
        let localizedBook = BibleData.localizedBookName(book, appLanguage: settingsStore.appLanguage)
        return "\(localizedBook) \(chapter):\(verse)"
    }
    
    private func formatVerseForShare(_ verse: DailyVerse) -> String {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Devotional"
    }
    
    private var savedNotesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Notes")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showSavedNotes = true
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.accentColor)
            }
            
            if noteStore.savedVerses.isEmpty {
                Text("No saved verses yet")
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
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
                            Text("View \(noteStore.savedVerses.count - 3) more...")
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
            .background(AppTheme.cardGradient(darkMode: SettingsStore.shared.isDarkMode))
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
            router.navigateToReading(book: book, chapter: savedVerse.chapter)
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
