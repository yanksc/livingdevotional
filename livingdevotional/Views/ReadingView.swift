// ReadingView - Displays verses in a scrollable view with dual-language support

import SwiftUI
import Foundation

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ReadingView: View {
    let bibleViewModel: BibleViewModel?
    
    @StateObject private var viewModel = ReadingViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showBookSelector = false
    @State private var showViewSettings = false
    @State private var selectedVerseId: String? = nil
    @State private var showSaveSheet = false
    @ObservedObject private var noteStore = NoteStore.shared
    @State private var pendingScrollVerse: Int?
    @State private var pendingScrollBook: String?
    @State private var pendingScrollChapter: Int?
    @State private var pendingScrollRetry: Int = 0
    @State private var hasCompletedInitialScroll: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @Environment(\.services) var services
    @State private var showChatSheet = false
    @State private var chatVerse: BibleVerse?
    
    // Zen Mode - Auto-hiding toolbar
    @State private var isToolbarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // AI Panel state
    @State private var showAIPanel: String? = nil // verse ID for which AI panel is shown
    @State private var aiPanelMode: AIMode = .insight // mode of the AI panel
    
    // Get current book and chapter from viewModel
    private var book: BibleBook? {
        bibleViewModel?.selectedBook
    }
    
    private var chapter: Int? {
        bibleViewModel?.selectedChapter
    }
    
    init(book: BibleBook, chapter: Int, bibleViewModel: BibleViewModel? = nil) {
        self.bibleViewModel = bibleViewModel
        // Capture initial target verse context from the view model (if provided via router)
        if let vm = bibleViewModel {
            self._pendingScrollVerse = State(initialValue: vm.targetVerse)
            self._pendingScrollBook = State(initialValue: vm.selectedBook?.name)
            self._pendingScrollChapter = State(initialValue: vm.selectedChapter)
        }
    }
    
    // MARK: - Navigation Helpers
    
    private var currentBookIndex: Int? {
        guard let book = book else { return nil }
        return BibleData.books.firstIndex(where: { $0.name == book.name })
    }
    
    private func navigateToNextChapter() {
        guard let book = book, let chapter = chapter else {
            return
        }
        
        guard let currentIndex = currentBookIndex else {
            return
        }
        
        // Check if there's a next chapter in current book
        if chapter < book.chapters {
                bibleViewModel?.selectChapter(chapter + 1)
            reloadVersesIfReady()
        } else {
            // Move to next book's first chapter
            if currentIndex < BibleData.books.count - 1 {
                let nextBook = BibleData.books[currentIndex + 1]
                    bibleViewModel?.selectBookAndChapter(nextBook, chapter: 1, targetVerse: nil)
                reloadVersesIfReady()
            }
        }
    }
    
    private func navigateToPreviousChapter() {
        guard let book = book, let chapter = chapter else {
            return
        }
        
        guard let currentIndex = currentBookIndex else {
            return
        }
        
        // Check if there's a previous chapter in current book
        if chapter > 1 {
                bibleViewModel?.selectChapter(chapter - 1)
            reloadVersesIfReady()
        } else {
            // Move to previous book's last chapter
            if currentIndex > 0 {
                let previousBook = BibleData.books[currentIndex - 1]
                    bibleViewModel?.selectBookAndChapter(previousBook, chapter: previousBook.chapters, targetVerse: nil)
                reloadVersesIfReady()
            }
        }
    }
    
    private var chapterText: String {
        guard let chapter = chapter else { return "" }
        let chapterPrefix = BibleData.localizedChapterText(language: settingsStore.primaryLanguage)
        if chapterPrefix == "第" {
            return "\(chapterPrefix)\(chapter)章"
        } else {
            return "\(chapterPrefix) \(chapter)"
        }
    }
    
    private var navigationTitleText: String {
        if let book = book, let chapter = chapter {
            return "\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter)"
        }
        return settingsStore.appLanguage.localizedString("Bible")
    }
    
    // MARK: - Helper Functions
    
    private func copyVerse(_ verse: BibleVerse) {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        let copyText = "\"\(text)\"\n- \(reference)"
        
        // Perform clipboard operation on a background queue to prevent main thread hang
        // This is a workaround for iOS Simulator pasteboard daemon hangs
        DispatchQueue.global(qos: .userInitiated).async { [copyText] in
            UIPasteboard.general.string = copyText
        }
    }
    
    private func shareVerse(_ verse: BibleVerse) {
        let shareText = formatVerseForShare(verse)
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Use DispatchQueue to ensure UI updates complete before presenting
            DispatchQueue.main.async {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func formatVerseForShare(_ verse: BibleVerse) -> String {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Devotional"
    }
    
    private func reloadVersesIfReady() {
        // Clear selected verse and AI panel when navigating to a new chapter
        selectedVerseId = nil
        showAIPanel = nil
        
        // Reload verses when both book and chapter are available
        if let book = bibleViewModel?.selectedBook,
           let chapter = bibleViewModel?.selectedChapter {
            Task { @MainActor in
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
        }
    }
    
    /// Use VStack (eager loading) when there's a pending scroll target to ensure scrollTo works
    private var shouldUseEagerLoading: Bool {
        return pendingScrollVerse != nil && !hasCompletedInitialScroll
    }
    
    /// Shared content for verses list (used by both VStack and LazyVStack)
    @ViewBuilder
    private var versesContent: some View {
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
            VStack(alignment: .leading, spacing: 0) {
                VerseView(
                    verse: verse,
                    settingsStore: settingsStore,
                    fontSize: settingsStore.fontSize,
                    isSelected: selectedVerseId == verse.id,
                    onTap: {
                        let wasSelected = selectedVerseId == verse.id
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            selectedVerseId = wasSelected ? nil : verse.id
                            // Close AI panel when deselecting
                            if wasSelected {
                                showAIPanel = nil
                            }
                        }
                    }
                )
                
                // Action bar (shown when verse is selected)
                if selectedVerseId == verse.id {
                    VerseActionBar(
                        verse: verse,
                        settingsStore: settingsStore,
                        onCopy: {
                            copyVerse(verse)
                        },
                        onShare: {
                            shareVerse(verse)
                        },
                        onAIInsight: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if showAIPanel == verse.id && aiPanelMode == .insight {
                                    showAIPanel = nil
                                } else {
                                    aiPanelMode = .insight
                                    showAIPanel = verse.id
                                }
                            }
                        },
                        onAIReflect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if showAIPanel == verse.id && aiPanelMode == .reflect {
                                    showAIPanel = nil
                                } else {
                                    aiPanelMode = .reflect
                                    showAIPanel = verse.id
                                }
                            }
                        },
                        onAIPray: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if showAIPanel == verse.id && aiPanelMode == .pray {
                                    showAIPanel = nil
                                } else {
                                    aiPanelMode = .pray
                                    showAIPanel = verse.id
                                }
                            }
                        },
                        onAIAsk: {
                            chatVerse = verse
                            showChatSheet = true
                        },
                        onSave: {
                            // Small delay to allow animation to complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showSaveSheet = true
                            }
                        }
                    )
                }
                
                // AI Panel (shown when AI action is requested)
                if showAIPanel == verse.id {
                    VerseAIPanel(
                        verse: verse,
                        mode: aiPanelMode,
                        settingsStore: settingsStore,
                        onClose: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAIPanel = nil
                            }
                        }
                    )
                }
            }
            .id(verse.id)
        }
    }
    
    /// Attempt to scroll to the pending target verse once verses are loaded.
    private func attemptScrollToPendingVerse(proxy: ScrollViewProxy, reason: String) {
        guard let targetVerse = pendingScrollVerse else { return }
        
        // Ensure verses belong to the pending book/chapter before attempting
        if let pendingBook = pendingScrollBook,
           let pendingChapter = pendingScrollChapter,
           let currentBook = viewModel.currentBook,
           let currentChapter = viewModel.currentChapter {
            if currentBook != pendingBook || currentChapter != pendingChapter {
                // #region agent log
                let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
                let logEntryBlock: [String: Any] = [
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "location": "ReadingView.attemptScrollToPendingVerse",
                    "message": "skipping scroll, verses not matching pending context",
                    "data": [
                        "pendingBook": pendingBook,
                        "pendingChapter": pendingChapter,
                        "currentBook": currentBook,
                        "currentChapter": currentChapter,
                        "reason": reason,
                        "pendingRetry": pendingScrollRetry,
                        "hypothesisId": "AUTO_SCROLL"
                    ],
                    "sessionId": "debug-session"
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: logEntryBlock),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                        fileHandle.closeFile()
                    } else {
                        try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                    }
                }
                // #endregion agent log
                
                if pendingScrollRetry < 8 {
                    pendingScrollRetry += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        attemptScrollToPendingVerse(proxy: proxy, reason: "context-retry-\(pendingScrollRetry)")
                    }
                }
                return
            }
        }
        guard let targetId = viewModel.verses.first(where: { $0.verseNumber == targetVerse })?.id else {
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let logEntry: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "ReadingView.attemptScrollToPendingVerse",
                "message": "pending verse not yet found",
                "data": [
                    "targetVerse": targetVerse,
                    "versesLoaded": viewModel.verses.count,
                    "pendingRetry": pendingScrollRetry,
                    "reason": reason,
                    "hypothesisId": "AUTO_SCROLL"
                ],
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
            // #endregion agent log
            
            // Retry a few times to wait for LazyVStack layout to materialize IDs
            if pendingScrollRetry < 8 {
                pendingScrollRetry += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    attemptScrollToPendingVerse(proxy: proxy, reason: "retry-\(pendingScrollRetry)")
                }
            } else {
                // Give up after retries
                pendingScrollVerse = nil
                pendingScrollBook = nil
                pendingScrollChapter = nil
            }
            return
        }
        
        // #region agent log
        let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
        let logEntry: [String: Any] = [
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "location": "ReadingView.attemptScrollToPendingVerse",
            "message": "scrolling to target verse",
            "data": [
                "targetVerse": targetVerse,
                "targetId": targetId,
                "versesLoaded": viewModel.verses.count,
                "pendingRetry": pendingScrollRetry,
                "reason": reason,
                "usingEagerLoading": shouldUseEagerLoading,
                "hypothesisId": "AUTO_SCROLL"
            ],
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
        // #endregion agent log
        
        // Add a small delay to ensure VStack has rendered all views
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let logEntryPre: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "ReadingView.attemptScrollToPendingVerse.scrollBlock",
                "message": "BEFORE scrollTo called",
                "data": [
                    "targetId": targetId,
                    "targetVerse": targetVerse,
                    "hasCompletedInitialScroll": hasCompletedInitialScroll,
                    "shouldUseEagerLoading": shouldUseEagerLoading,
                    "hypothesisId": "F"
                ],
                "sessionId": "debug-session"
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntryPre),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                }
            }
            // #endregion agent log
            
            withAnimation(.easeInOut) {
                proxy.scrollTo(targetId, anchor: .top)
            }
            
            // #region agent log
            let logEntryPost: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "ReadingView.attemptScrollToPendingVerse.scrollBlock",
                "message": "AFTER scrollTo, BEFORE clearing state",
                "data": [
                    "targetId": targetId,
                    "hypothesisId": "F"
                ],
                "sessionId": "debug-session"
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntryPost),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                }
            }
            // #endregion agent log
            
            // DELAY clearing state to allow scroll animation to complete (fix for Hypothesis F)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // #region agent log
                let logEntryCleared: [String: Any] = [
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "location": "ReadingView.attemptScrollToPendingVerse.scrollBlock",
                    "message": "NOW clearing state after delay",
                    "data": [
                        "hypothesisId": "F"
                    ],
                    "sessionId": "debug-session"
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: logEntryCleared),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                        fileHandle.closeFile()
                    } else {
                        try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                    }
                }
                // #endregion agent log
                
                // Mark scroll as completed and clear pending state
                hasCompletedInitialScroll = true
                pendingScrollVerse = nil
                bibleViewModel?.targetVerse = nil
                pendingScrollRetry = 0
                pendingScrollBook = nil
                pendingScrollChapter = nil
            }
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
                        // Main scrollable content with scroll tracking
                        ScrollViewReader { proxy in
                            ScrollView {
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                                }
                                .frame(height: 0)
                                
                                // Use VStack (eager loading) when pending scroll to ensure all views render
                                // Use LazyVStack for better performance after scroll completes
                                Group {
                                    if shouldUseEagerLoading {
                                        VStack(alignment: .leading, spacing: settingsStore.lineSpacing) {
                                            versesContent
                                        }
                                        .onAppear {
                                            // #region agent log
                                            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
                                            let logEntry: [String: Any] = [
                                                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                                                "location": "ReadingView.VStack",
                                                "message": "using EAGER loading (VStack)",
                                                "data": [
                                                    "pendingVerse": pendingScrollVerse ?? -1,
                                                    "hasCompletedInitialScroll": hasCompletedInitialScroll,
                                                    "versesCount": viewModel.verses.count,
                                                    "hypothesisId": "AUTO_SCROLL"
                                                ],
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
                                            // #endregion agent log
                                        }
                                    } else {
                                        LazyVStack(alignment: .leading, spacing: settingsStore.lineSpacing) {
                                            versesContent
                                        }
                                    }
                                }
                                .padding(.bottom, 40) // Extra padding for safe area
                            }
                            .coordinateSpace(name: "scroll")
                            .onAppear {
                                scrollProxy = proxy
                                // Sync pending target with view model on appear
                                if pendingScrollVerse == nil {
                                    if let targetVerse = bibleViewModel?.targetVerse {
                                        pendingScrollVerse = targetVerse
                                        pendingScrollBook = bibleViewModel?.selectedBook?.name
                                        pendingScrollChapter = bibleViewModel?.selectedChapter
                                        hasCompletedInitialScroll = false
                                    }
                                }
                                attemptScrollToPendingVerse(proxy: proxy, reason: "onAppear")
                            }
                            .onChange(of: viewModel.verses) { _ in
                                attemptScrollToPendingVerse(proxy: proxy, reason: "versesChanged")
                            }
                            .onChange(of: pendingScrollVerse) { _ in
                                attemptScrollToPendingVerse(proxy: proxy, reason: "pendingVerseChanged")
                            }
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                let newOffset = value
                                let delta = newOffset - lastScrollOffset
                                
                                // Hide toolbar when scrolling down, show when scrolling up
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if delta < -10 {
                                        // Scrolling down
                                        isToolbarVisible = false
                                    } else if delta > 10 {
                                        // Scrolling up
                                        isToolbarVisible = true
                                    }
                                }
                                
                                lastScrollOffset = newOffset
                                scrollOffset = newOffset
                            }
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
                                            
                                            // Swipe right (positive horizontal) from left edge = previous chapter
                                            if horizontalAmount > 50 && abs(horizontalAmount) > abs(verticalAmount) {
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
                                            
                                            // Swipe left (negative horizontal) from right edge = next chapter
                                            if horizontalAmount < -50 && abs(horizontalAmount) > abs(verticalAmount) {
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
        .toolbarBackground(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
        .preferredColorScheme(settingsStore.isDarkMode ? .dark : .light)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
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
        .sheet(isPresented: $showChatSheet) {
            if let verse = chatVerse, let aiService = services.aiService {
                ChatView(
                    viewModel: ChatViewModel(
                        aiService: aiService,
                        book: verse.book,
                        chapter: verse.chapter,
                        verse: verse.verseNumber,
                        verseText: verse.text(for: settingsStore.primaryLanguage),
                        appLanguage: settingsStore.appLanguage
                    ),
                    settingsStore: settingsStore,
                    onClose: {
                        showChatSheet = false
                    }
                )
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showViewSettings) {
            ReadingSettingsView(isPresented: $showViewSettings)
        }
        .sheet(isPresented: $showSaveSheet) {
            if let selectedId = selectedVerseId,
               let verse = viewModel.verses.first(where: { $0.id == selectedId }),
               let book = book {
                SaveVerseSheet(
                    verse: verse,
                    book: book,
                    chapter: chapter ?? 1,
                    settingsStore: settingsStore,
                    noteStore: noteStore
                )
                .presentationDetents([.medium, .large])
                .onDisappear {
                    // Reload saved verses after sheet is dismissed
                    noteStore.loadSavedVerses()
                }
            }
        }
        .onAppear {
            // Reload saved verses to ensure we have the latest state
            noteStore.loadSavedVerses()
            // Capture any target verse passed through the view model
            if pendingScrollVerse == nil {
                if let targetVerse = bibleViewModel?.targetVerse {
                    pendingScrollVerse = targetVerse
                    pendingScrollBook = bibleViewModel?.selectedBook?.name
                    pendingScrollChapter = bibleViewModel?.selectedChapter
                    hasCompletedInitialScroll = false // Reset for new target
                }
            }
            if let proxy = scrollProxy {
                attemptScrollToPendingVerse(proxy: proxy, reason: "onAppear-root")
            }
        }
        .onChange(of: bibleViewModel?.selectedBook) { oldBook, newBook in
            reloadVersesIfReady()
        }
        .onChange(of: bibleViewModel?.selectedChapter) { oldChapter, newChapter in
            reloadVersesIfReady()
        }
        .onChange(of: bibleViewModel?.targetVerse) { _, newTarget in
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let logEntry: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "ReadingView.onChange(targetVerse)",
                "message": "targetVerse changed",
                "data": [
                    "newTarget": newTarget as Any,
                    "pendingScrollVerse": pendingScrollVerse as Any,
                    "hasCompletedInitialScroll": hasCompletedInitialScroll,
                    "scrollProxyExists": scrollProxy != nil,
                    "hypothesisId": "E"
                ],
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
            // #endregion agent log
            
            if newTarget != nil {
                // Reset scroll completion state for new target
                hasCompletedInitialScroll = false
            }
            pendingScrollVerse = newTarget
            pendingScrollBook = bibleViewModel?.selectedBook?.name
            pendingScrollChapter = bibleViewModel?.selectedChapter
            pendingScrollRetry = 0
            if let proxy = scrollProxy {
                attemptScrollToPendingVerse(proxy: proxy, reason: "targetVerseChanged-root")
            }
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
    @ObservedObject var noteStore = NoteStore.shared
    let fontSize: Double
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    init(verse: BibleVerse, settingsStore: SettingsStore, fontSize: Double, isSelected: Bool, onTap: @escaping () -> Void, onLongPress: (() -> Void)? = nil) {
        self.verse = verse
        self.settingsStore = settingsStore
        self.fontSize = fontSize
        self.isSelected = isSelected
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var isSaved: Bool {
        noteStore.isVerseSaved(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
    }
    
    var primaryText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var secondaryText: String {
        verse.text(for: settingsStore.secondaryLanguage)
    }
    
    private func formatVerseForShare(_ verse: BibleVerse) -> String {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Devotional"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Verse number with save indicator
            HStack(spacing: 4) {
                Text("\(verse.verseNumber)")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(isSaved ? AppTheme.accentColor : AppTheme.verseNumberColor(darkMode: settingsStore.isDarkMode))
                
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: fontSize * 0.6))
                        .foregroundColor(AppTheme.accentColor)
                }
            }
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
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    AppTheme.verseSelectionGradient(darkMode: settingsStore.isDarkMode)
                        .cornerRadius(8)
                } else if isSaved {
                    AppTheme.accentColor.opacity(0.05)
                        .cornerRadius(8)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            Group {
                if isSaved && !isSelected {
                    Rectangle()
                        .frame(width: 3)
                        .foregroundColor(AppTheme.accentColor)
                        .cornerRadius(1.5)
                } else {
                    Color.clear
                }
            },
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                // Copy verse
                let text = verse.text(for: settingsStore.primaryLanguage)
                let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
                UIPasteboard.general.string = "\"\(text)\"\n- \(reference)"
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            ShareLink(item: formatVerseForShare(verse)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            if let onLongPress = onLongPress {
                Button {
                    onLongPress()
                } label: {
                    Label("AI Insight", systemImage: "sparkles")
                }
            }
        }
    }
}

struct ReadingSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(settingsStore.appLanguage.localizedString("FontSize"))) {
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
                
                Section(header: Text(settingsStore.appLanguage.localizedString("LineSpacing"))) {
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
                
                Section(header: Text(settingsStore.appLanguage.localizedString("Language"))) {
                    Toggle(settingsStore.appLanguage.localizedString("ShowSecondLanguage"), isOn: $settingsStore.showSecondaryLanguage)
                        .tint(AppTheme.accentColor)
                }
                
                Section(header: Text(settingsStore.appLanguage.localizedString("Appearance"))) {
                    Toggle(settingsStore.appLanguage.localizedString("DarkMode"), isOn: $settingsStore.isDarkMode)
                        .tint(AppTheme.accentColor)
                }
            }
            .navigationTitle(settingsStore.appLanguage.localizedString("ViewSettings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsStore.appLanguage.localizedString("Done")) {
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

// MARK: - Floating Action Button Menu Item

struct FABMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.trailing, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardGradient(darkMode: false))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        ReadingView(book: BibleData.books[45], chapter: 3)
    }
}
