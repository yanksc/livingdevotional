// ReadingView - Displays verses in a scrollable view with dual-language support

import SwiftUI

struct ReadingView: View {
    let book: BibleBook
    let chapter: Int
    let bibleViewModel: BibleViewModel?
    
    @StateObject private var viewModel = ReadingViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    
    init(book: BibleBook, chapter: Int, bibleViewModel: BibleViewModel? = nil) {
        self.book = book
        self.chapter = chapter
        self.bibleViewModel = bibleViewModel
    }
    
    private var chapterText: String {
        switch settingsStore.primaryLanguage {
        case .cuv, .cu1:
            return "第\(chapter)章"
        case .bsb, .none:
            return "Chapter \(chapter)"
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Content
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(AppTheme.accentColor)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error loading verses")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            viewModel.refreshVerses()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.verses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.secondaryText)
                        Text("No verses found")
                            .font(.headline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Chapter header with gradient
                            VStack(alignment: .leading, spacing: 8) {
                                Text(book.localizedName(for: settingsStore.primaryLanguage))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(chapterText)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [
                                        AppTheme.primaryBlue.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            // Verses
                            ForEach(viewModel.verses) { verse in
                                VerseView(verse: verse, settingsStore: settingsStore)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Update viewModel state and dismiss in one action
                    // dismiss() will pop the navigation stack
                    bibleViewModel?.goBackToChapterList()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Chapters")
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
        .task {
            await viewModel.loadVerses(book: book.name, chapter: chapter)
        }
        .refreshable {
            await viewModel.loadVerses(book: book.name, chapter: chapter)
        }
    }
}

struct VerseView: View {
    let verse: BibleVerse
    @ObservedObject var settingsStore: SettingsStore
    
    var primaryText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var secondaryText: String {
        verse.text(for: settingsStore.secondaryLanguage)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number - simple text without background
            Text("\(verse.verseNumber)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.verseNumberColor)
                .frame(minWidth: 28, alignment: .leading)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 10) {
                // Primary language text
                if !primaryText.isEmpty && settingsStore.primaryLanguage != .none {
                    Text(primaryText)
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Secondary language text (if not none and different from primary)
                if !secondaryText.isEmpty && 
                   settingsStore.secondaryLanguage != .none &&
                   settingsStore.secondaryLanguage != settingsStore.primaryLanguage {
                    Text(secondaryText)
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        ReadingView(book: BibleData.books[45], chapter: 3)
    }
}

