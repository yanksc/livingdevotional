// ReadingView - Displays verses in a scrollable view with dual-language support

import SwiftUI
import Foundation

// MARK: - Debug Logging Helper
// #region agent log
private func debugLog(_ message: String, data: [String: Any] = [:]) {
    let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
    let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    let logEntry: [String: Any] = [
        "timestamp": timestamp,
        "location": "ReadingView.swift",
        "message": message,
        "data": data,
        "sessionId": "debug-session"
    ]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
         if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write((jsonString + "\n").data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    }
}
// #endregion agent log

struct ReadingView: View {
    let bibleViewModel: BibleViewModel?
    
    @StateObject private var viewModel = ReadingViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showBookSelector = false
    @State private var showViewSettings = false
    
    // Get current book and chapter from viewModel
    private var book: BibleBook? {
        bibleViewModel?.selectedBook
    }
    
    private var chapter: Int? {
        bibleViewModel?.selectedChapter
    }
    
    init(book: BibleBook, chapter: Int, bibleViewModel: BibleViewModel? = nil) {
        self.bibleViewModel = bibleViewModel
    }
    
    // MARK: - Navigation Helpers
    
    private var currentBookIndex: Int? {
        guard let book = book else { return nil }
        return BibleData.books.firstIndex(where: { $0.name == book.name })
    }
    
    private func navigateToNextChapter() {
        // #region agent log
        debugLog("navigateToNextChapter called", data: [
            "book": book?.name ?? "nil",
            "chapter": chapter ?? -1,
            "bookChapters": book?.chapters ?? -1,
            "bibleViewModelExists": bibleViewModel != nil,
            "currentBookIndex": currentBookIndex ?? -1,
            "hypothesisId": "H1"
        ])
        // #endregion agent log
        
        guard let book = book, let chapter = chapter else {
            // #region agent log
            debugLog("navigateToNextChapter: guard failed - book or chapter is nil", data: [
                "book": self.book?.name ?? "nil",
                "chapter": self.chapter ?? -1,
                "hypothesisId": "H1"
            ])
            // #endregion agent log
            return
        }
        
        // #region agent log
        debugLog("navigateToNextChapter: first guard passed", data: [
            "book": book.name,
            "chapter": chapter,
            "hypothesisId": "H1"
        ])
        // #endregion agent log
        
        guard let currentIndex = currentBookIndex else {
            // #region agent log
            debugLog("navigateToNextChapter: currentBookIndex is nil", data: [
                "book": book.name,
                "hypothesisId": "H2"
            ])
            // #endregion agent log
            return
        }
        
        // #region agent log
        debugLog("navigateToNextChapter: currentIndex found", data: ["currentIndex": currentIndex])
        // #endregion agent log
        
        // Check if there's a next chapter in current book
        if chapter < book.chapters {
            // Move to next chapter in same book
            // #region agent log
            debugLog("navigateToNextChapter: moving to next chapter in same book", data: ["nextChapter": chapter + 1])
            // #endregion agent log
            // #region agent log
            debugLog("navigateToNextChapter: calling selectChapter", data: [
                "targetChapter": chapter + 1,
                "bibleViewModelExists": bibleViewModel != nil,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            bibleViewModel?.selectChapter(chapter + 1)
            // #region agent log
            debugLog("navigateToNextChapter: after selectChapter", data: [
                "selectedBook": bibleViewModel?.selectedBook?.name ?? "nil",
                "selectedChapter": bibleViewModel?.selectedChapter ?? -1,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            // Manually trigger reload since onChange may not fire reliably
            // #region agent log
            debugLog("navigateToNextChapter: manually calling reloadVersesIfReady", data: ["hypothesisId": "FIX"])
            // #endregion agent log
            reloadVersesIfReady()
        } else {
            // Move to next book's first chapter
            if currentIndex < BibleData.books.count - 1 {
                let nextBook = BibleData.books[currentIndex + 1]
                // #region agent log
                debugLog("navigateToNextChapter: moving to next book", data: [
                    "nextBook": nextBook.name,
                    "nextBookChapters": nextBook.chapters
                ])
                // #endregion agent log
                // #region agent log
            debugLog("navigateToNextChapter: calling selectBookAndChapter", data: [
                "nextBook": nextBook.name,
                "targetChapter": 1,
                "bibleViewModelExists": bibleViewModel != nil,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            bibleViewModel?.selectBookAndChapter(nextBook, chapter: 1)
            // #region agent log
            debugLog("navigateToNextChapter: after selectBookAndChapter", data: [
                "selectedBook": bibleViewModel?.selectedBook?.name ?? "nil",
                "selectedChapter": bibleViewModel?.selectedChapter ?? -1,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            // Manually trigger reload since onChange may not fire reliably
            // #region agent log
            debugLog("navigateToNextChapter: manually calling reloadVersesIfReady", data: ["hypothesisId": "FIX"])
            // #endregion agent log
            reloadVersesIfReady()
            } else {
                // #region agent log
                debugLog("navigateToNextChapter: already at last book", data: ["currentIndex": currentIndex, "totalBooks": BibleData.books.count])
                // #endregion agent log
            }
        }
    }
    
    private func navigateToPreviousChapter() {
        // #region agent log
        debugLog("navigateToPreviousChapter called", data: [
            "book": book?.name ?? "nil",
            "chapter": chapter ?? -1,
            "bibleViewModelExists": bibleViewModel != nil,
            "currentBookIndex": currentBookIndex ?? -1,
            "hypothesisId": "H1"
        ])
        // #endregion agent log
        
        guard let book = book, let chapter = chapter else {
            // #region agent log
            debugLog("navigateToPreviousChapter: guard failed - book or chapter is nil", data: [
                "book": self.book?.name ?? "nil",
                "chapter": self.chapter ?? -1,
                "hypothesisId": "H1"
            ])
            // #endregion agent log
            return
        }
        
        // #region agent log
        debugLog("navigateToPreviousChapter: first guard passed", data: [
            "book": book.name,
            "chapter": chapter,
            "hypothesisId": "H1"
        ])
        // #endregion agent log
        
        guard let currentIndex = currentBookIndex else {
            // #region agent log
            debugLog("navigateToPreviousChapter: currentBookIndex is nil", data: [
                "book": book.name,
                "hypothesisId": "H2"
            ])
            // #endregion agent log
            return
        }
        
        // #region agent log
        debugLog("navigateToPreviousChapter: currentIndex found", data: ["currentIndex": currentIndex])
        // #endregion agent log
        
        // Check if there's a previous chapter in current book
        if chapter > 1 {
            // Move to previous chapter in same book
            // #region agent log
            debugLog("navigateToPreviousChapter: moving to previous chapter in same book", data: ["prevChapter": chapter - 1])
            // #endregion agent log
            // #region agent log
            debugLog("navigateToPreviousChapter: calling selectChapter", data: [
                "targetChapter": chapter - 1,
                "bibleViewModelExists": bibleViewModel != nil,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            bibleViewModel?.selectChapter(chapter - 1)
            // #region agent log
            debugLog("navigateToPreviousChapter: after selectChapter", data: [
                "selectedBook": bibleViewModel?.selectedBook?.name ?? "nil",
                "selectedChapter": bibleViewModel?.selectedChapter ?? -1,
                "hypothesisId": "H3"
            ])
            // #endregion agent log
            // Manually trigger reload since onChange may not fire reliably
            // #region agent log
            debugLog("navigateToNextChapter: manually calling reloadVersesIfReady", data: ["hypothesisId": "FIX"])
            // #endregion agent log
            reloadVersesIfReady()
        } else {
            // Move to previous book's last chapter
            if currentIndex > 0 {
                let previousBook = BibleData.books[currentIndex - 1]
                // #region agent log
                debugLog("navigateToPreviousChapter: moving to previous book", data: [
                    "prevBook": previousBook.name,
                    "prevBookChapters": previousBook.chapters
                ])
                // #endregion agent log
                // #region agent log
                debugLog("navigateToPreviousChapter: calling selectBookAndChapter", data: [
                    "previousBook": previousBook.name,
                    "targetChapter": previousBook.chapters,
                    "bibleViewModelExists": bibleViewModel != nil,
                    "hypothesisId": "H3"
                ])
                // #endregion agent log
                bibleViewModel?.selectBookAndChapter(previousBook, chapter: previousBook.chapters)
                // #region agent log
                debugLog("navigateToPreviousChapter: after selectBookAndChapter", data: [
                    "selectedBook": bibleViewModel?.selectedBook?.name ?? "nil",
                    "selectedChapter": bibleViewModel?.selectedChapter ?? -1,
                    "hypothesisId": "H3"
                ])
                // #endregion agent log
                // Manually trigger reload since onChange may not fire reliably
                // #region agent log
                debugLog("navigateToPreviousChapter: manually calling reloadVersesIfReady", data: ["hypothesisId": "FIX"])
                // #endregion agent log
                reloadVersesIfReady()
            } else {
                // #region agent log
                debugLog("navigateToPreviousChapter: already at first book", data: ["currentIndex": currentIndex])
                // #endregion agent log
            }
        }
    }
    
    private var chapterText: String {
        guard let chapter = chapter else { return "" }
        switch settingsStore.primaryLanguage {
        case .cuv, .cu1:
            return "第\(chapter)章"
        case .bsb, .kjv, .none:
            return "Chapter \(chapter)"
        }
    }
    
    private var navigationTitleText: String {
        if let book = book, let chapter = chapter {
            return "\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter)"
        }
        return "Bible"
    }
    
    private func reloadVersesIfReady() {
        // #region agent log
        debugLog("reloadVersesIfReady called", data: [
            "selectedBook": bibleViewModel?.selectedBook?.name ?? "nil",
            "selectedChapter": bibleViewModel?.selectedChapter ?? -1,
            "hypothesisId": "H4"
        ])
        // #endregion agent log
        
        // Reload verses when both book and chapter are available
        if let book = bibleViewModel?.selectedBook,
           let chapter = bibleViewModel?.selectedChapter {
            // #region agent log
            debugLog("reloadVersesIfReady: both available, calling loadVerses", data: [
                "book": book.name,
                "chapter": chapter,
                "hypothesisId": "H4"
            ])
            // #endregion agent log
            Task { @MainActor in
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
        } else {
            // #region agent log
            debugLog("reloadVersesIfReady: not ready, skipping", data: [
                "bookAvailable": bibleViewModel?.selectedBook != nil,
                "chapterAvailable": bibleViewModel?.selectedChapter != nil,
                "hypothesisId": "H4"
            ])
            // #endregion agent log
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode)
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
                    ZStack {
                        // Main scrollable content
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: settingsStore.lineSpacing) {
                                // Spacer to account for large navigation title
                                Color.clear
                                    .frame(height: 8)
                                
                                // Chapter header - subtle and elegant
                                HStack {
                                    Text(chapterText)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryText)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                                
                                // Verses
                                ForEach(viewModel.verses) { verse in
                                    VerseView(verse: verse, settingsStore: settingsStore, fontSize: settingsStore.fontSize)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        
                        // Edge swipe gesture overlays (iOS 17+ modern approach)
                        HStack(spacing: 0) {
                            // Left edge - swipe right for previous chapter
                            Color.clear
                                .frame(width: 30)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 50)
                                        .onEnded { value in
                                            let horizontalAmount = value.translation.width
                                            let verticalAmount = value.translation.height
                                            
                                            // #region agent log
                                            debugLog("LEFT edge gesture triggered", data: [
                                                "horizontalAmount": horizontalAmount,
                                                "verticalAmount": verticalAmount,
                                                "isHorizontal": abs(horizontalAmount) > abs(verticalAmount)
                                            ])
                                            // #endregion agent log
                                            
                                            // Swipe right (positive horizontal) from left edge = previous chapter
                                            if horizontalAmount > 50 && abs(horizontalAmount) > abs(verticalAmount) {
                                                // #region agent log
                                                debugLog("LEFT edge: navigating to previous chapter")
                                                // #endregion agent log
                                                navigateToPreviousChapter()
                                            }
                                        }
                                )
                            
                            Spacer()
                            
                            // Right edge - swipe left for next chapter
                            Color.clear
                                .frame(width: 30)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 50)
                                        .onEnded { value in
                                            let horizontalAmount = value.translation.width
                                            let verticalAmount = value.translation.height
                                            
                                            // #region agent log
                                            debugLog("RIGHT edge gesture triggered", data: [
                                                "horizontalAmount": horizontalAmount,
                                                "verticalAmount": verticalAmount,
                                                "isHorizontal": abs(horizontalAmount) > abs(verticalAmount)
                                            ])
                                            // #endregion agent log
                                            
                                            // Swipe left (negative horizontal) from right edge = next chapter
                                            if horizontalAmount < -50 && abs(horizontalAmount) > abs(verticalAmount) {
                                                // #region agent log
                                                debugLog("RIGHT edge: navigating to next chapter")
                                                // #endregion agent log
                                                navigateToNextChapter()
                                            }
                                        }
                                )
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(settingsStore.isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // #region agent log
                    debugLog("PREVIOUS button clicked", data: [
                        "book": book?.name ?? "nil",
                        "chapter": chapter ?? -1,
                        "currentBookIndex": currentBookIndex ?? -1,
                        "isDisabled": (chapter ?? 1) == 1 && currentBookIndex == 0,
                        "hypothesisId": "H5"
                    ])
                    // #endregion agent log
                    navigateToPreviousChapter()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled((chapter ?? 1) == 1 && currentBookIndex == 0)
            }
            
            ToolbarItem(placement: .principal) {
                Button {
                    showBookSelector = true
                } label: {
                    HStack(spacing: 6) {
                        if let book = book, let chapter = chapter {
                            Text("\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter)")
                                .foregroundColor(.primary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showViewSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                        .foregroundColor(AppTheme.accentColor)
                }
                
                Button {
                    // #region agent log
                    debugLog("NEXT button clicked", data: [
                        "book": book?.name ?? "nil",
                        "chapter": chapter ?? -1,
                        "bookChapters": book?.chapters ?? -1,
                        "currentBookIndex": currentBookIndex ?? -1,
                        "totalBooks": BibleData.books.count,
                        "isDisabled": (chapter ?? 0) == (book?.chapters ?? 0) && currentBookIndex == BibleData.books.count - 1,
                        "hypothesisId": "H5"
                    ])
                    // #endregion agent log
                    navigateToNextChapter()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled((chapter ?? 0) == (book?.chapters ?? 0) && currentBookIndex == BibleData.books.count - 1)
            }
        }
        .navigationTitle(navigationTitleText)
        .sheet(isPresented: $showBookSelector) {
            if let viewModel = bibleViewModel {
                BookSelectionSheet(viewModel: viewModel, isPresented: $showBookSelector)
            }
        }
        .sheet(isPresented: $showViewSettings) {
            ReadingSettingsView(isPresented: $showViewSettings)
        }
        .onChange(of: bibleViewModel?.selectedBook) { oldBook, newBook in
            // #region agent log
            debugLog("onChange selectedBook triggered", data: [
                "oldBook": oldBook?.name ?? "nil",
                "newBook": newBook?.name ?? "nil",
                "currentChapter": bibleViewModel?.selectedChapter ?? -1,
                "hypothesisId": "H1"
            ])
            // #endregion agent log
            reloadVersesIfReady()
        }
        .onChange(of: bibleViewModel?.selectedChapter) { oldChapter, newChapter in
            // #region agent log
            debugLog("onChange selectedChapter triggered", data: [
                "oldChapter": oldChapter ?? -1,
                "newChapter": newChapter ?? -1,
                "currentBook": bibleViewModel?.selectedBook?.name ?? "nil",
                "hypothesisId": "H1"
            ])
            // #endregion agent log
            reloadVersesIfReady()
        }
        .task {
            if let book = book, let chapter = chapter {
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
        }
        .refreshable {
            if let book = book, let chapter = chapter {
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
        }
    }
}

struct VerseView: View {
    let verse: BibleVerse
    @ObservedObject var settingsStore: SettingsStore
    let fontSize: Double
    
    var primaryText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var secondaryText: String {
        verse.text(for: settingsStore.secondaryLanguage)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Verse number - simple text without background
            Text("\(verse.verseNumber)")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(AppTheme.verseNumberColor(darkMode: settingsStore.isDarkMode))
                .frame(minWidth: 28, alignment: .leading)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: settingsStore.lineSpacing) {
                // Primary language text
                if !primaryText.isEmpty && settingsStore.primaryLanguage != .none {
                    Text(primaryText)
                        .font(.system(size: fontSize))
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(settingsStore.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Secondary language text (if not none and different from primary)
                if settingsStore.showSecondaryLanguage &&
                   !secondaryText.isEmpty && 
                   settingsStore.secondaryLanguage != .none &&
                   settingsStore.secondaryLanguage != settingsStore.primaryLanguage {
                    Text(secondaryText)
                        .font(.system(size: fontSize))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(settingsStore.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReadingSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Font Size")) {
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Slider(value: $settingsStore.fontSize, in: 12...24, step: 1)
                        Image(systemName: "textformat.size.larger")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("\(Int(settingsStore.fontSize))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                Section(header: Text("Line Spacing")) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Slider(value: $settingsStore.lineSpacing, in: 0...16, step: 2)
                        Image(systemName: "arrow.up.and.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("\(Int(settingsStore.lineSpacing))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                Section(header: Text("Language")) {
                    Toggle("Show Second Language", isOn: $settingsStore.showSecondaryLanguage)
                        .tint(AppTheme.accentColor)
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $settingsStore.isDarkMode)
                        .tint(AppTheme.accentColor)
                }
            }
            .navigationTitle("View Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        ReadingView(book: BibleData.books[45], chapter: 3)
    }
}

