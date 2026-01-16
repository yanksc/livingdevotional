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
    @EnvironmentObject var router: AppRouter
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
    @State private var usedNearEndScroll: Bool = false // Track if we did any targeted scroll (keep eager loading)
    @Environment(\.services) var services
    @State private var showChatSheet = false
    @State private var chatVerse: BibleVerse?
    @State private var pendingChatSessionId: String?
    @State private var showRelatedVersesSheet = false
    @State private var relatedVerse: BibleVerse?
    @State private var showChapterContextSheet = false
    @State private var showChapterSummarySheet = false
    @State private var chapterContextOffset: CGFloat = UIScreen.main.bounds.width
    @State private var chapterSummaryOffset: CGFloat = UIScreen.main.bounds.width
    @State private var relatedVersesOffset: CGFloat = UIScreen.main.bounds.width
    @State private var showPrayerFlow = false
    
    // Zen Mode - Auto-hiding toolbar and tab bar
    @State private var isToolbarVisible = true
    @State private var isTabBarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // Verse Panel state
    @State private var showAIPanel: String? = nil // verse ID for which verse panel is shown
    @State private var aiPanelMode: AIMode = .insight // mode of the verse panel
    
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
        guard let chapter = chapter else {
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
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Path"
    }
    
    private func reloadVersesIfReady() {
        // Clear selected verse and verse panel when navigating to a new chapter
        selectedVerseId = nil
        showAIPanel = nil
        
        // Reset targeted scroll flag when navigating to new chapter
        usedNearEndScroll = false
        
        // Reload verses when both book and chapter are available
        if let book = bibleViewModel?.selectedBook,
           let chapter = bibleViewModel?.selectedChapter {
            Task { @MainActor in
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
        }
    }
    
    /// Use VStack (eager loading) when there's a pending scroll target to ensure scrollTo works
    /// Also keep eager loading after ANY targeted scroll to prevent scroll position jumps
    /// (Switching VStack→LazyVStack causes layout recalculation that shifts scroll position)
    private var shouldUseEagerLoading: Bool {
        return (pendingScrollVerse != nil && !hasCompletedInitialScroll) || usedNearEndScroll
    }
    
    /// Check if a verse is near the end of the chapter (within last 4 verses)
    /// This helps determine if we should scroll to bottom instead of top to avoid overscroll issues
    private func isVerseNearEnd(_ verseNumber: Int) -> Bool {
        guard !viewModel.verses.isEmpty else { return false }
        let lastVerseNumber = viewModel.verses.last?.verseNumber ?? 0
        let threshold = 4 // Consider last 4 verses as "near end"
        
        // Check if verse is within threshold verses from the end
        return verseNumber > (lastVerseNumber - threshold)
    }
    
    /// Shared content for verses list (used by both VStack and LazyVStack)
    @ViewBuilder
    private var versesContent: some View {
        // Spacer to account for large navigation title
        Color.clear
            .frame(height: 8)
        
        // Chapter header - subtle and elegant with context and summary buttons
        HStack {
            Text(chapterText)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
            
            // Chapter Context button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showChapterContextSheet = true
                    }
                } label: {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10, weight: .regular))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "背景" : "Context")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.05))
                )
            }
            
            // Chapter Summary button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showChapterSummarySheet = true
                    }
                } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10, weight: .regular))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "摘要" : "Summary")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.05))
                )
            }
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
                            // Close verse panel when deselecting
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
                            // Pass the selected verse to skip verse selection
                            showPrayerFlow = true
                        },
                        onAIAsk: {
                            chatVerse = verse
                            showChatSheet = true
                        },
                        onRelated: {
                            relatedVerse = verse
                            showRelatedVersesSheet = true
                        },
                        onSave: {
                            // Small delay to allow animation to complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showSaveSheet = true
                            }
                        }
                    )
                }
                
                // Verse Panel (shown when verse action is requested)
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
                // Verses not yet loaded for target book/chapter, retry
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
            // Target verse not yet found in loaded verses, retry
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
        
        // Determine if this verse is near the end of the chapter
        let isNearEnd = isVerseNearEnd(targetVerse)
        
        // For near-end verses, scroll to the target verse with bottom anchor to avoid overscroll
        // This ensures the target verse is visible at the bottom, all verses above are visible,
        // and the bottom navbar doesn't disappear due to overscroll
        // For other verses, use the existing top anchor behavior
        let scrollTargetId: String
        let scrollAnchor: UnitPoint
        
        if isNearEnd {
            // Scroll to the LAST verse of the chapter with bottom anchor
            // This ensures ALL verses including the last one are visible
            // and prevents overscroll that causes verses to disappear and navbar to hide
            if let lastVerse = viewModel.verses.last {
                scrollTargetId = lastVerse.id
                scrollAnchor = .bottom
            } else {
                // Fallback to target verse if no last verse found
                scrollTargetId = targetId
                scrollAnchor = .bottom
            }
        } else {
            // Normal behavior: scroll target verse to top
            scrollTargetId = targetId
            scrollAnchor = .top
        }
        
        // Add a small delay to ensure VStack has rendered all views
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Set flag to keep eager loading active after ANY targeted scroll
            // This prevents VStack→LazyVStack switch that causes scroll position jumps
            // (Previously only for near-end, but ALL verses experience jump on switch)
            self.usedNearEndScroll = true
            
            withAnimation(.easeInOut) {
                proxy.scrollTo(scrollTargetId, anchor: scrollAnchor)
            }
            
            // Delay clearing state to allow scroll animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                            .onChange(of: viewModel.verses) { _, _ in
                                attemptScrollToPendingVerse(proxy: proxy, reason: "versesChanged")
                            }
                            .onChange(of: pendingScrollVerse) { _, _ in
                                attemptScrollToPendingVerse(proxy: proxy, reason: "pendingVerseChanged")
                            }
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                let newOffset = value
                                let delta = newOffset - lastScrollOffset
                                
                                // Hide toolbar and tab bar when scrolling down, show when scrolling up
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if delta < -10 {
                                        // Scrolling down
                                        isToolbarVisible = false
                                        isTabBarVisible = false
                                    } else if delta > 10 {
                                        // Scrolling up
                                        isToolbarVisible = true
                                        isTabBarVisible = true
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
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
        .toolbar(isTabBarVisible && !showRelatedVersesSheet && !showChapterContextSheet && !showChapterSummarySheet ? .visible : .hidden, for: .tabBar)
        .preferredColorScheme(.light)
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
                    Image(systemName: "slider.horizontal.3")
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
                        appLanguage: settingsStore.appLanguage,
                        sessionId: pendingChatSessionId
                    ),
                    settingsStore: settingsStore,
                    onClose: {
                        showChatSheet = false
                        pendingChatSessionId = nil
                    }
                )
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatSession"))) { notification in
            guard let sessionId = notification.userInfo?["sessionId"] as? String,
                  let session = ChatStore.shared.getSession(id: sessionId) else {
                return
            }
            
            pendingChatSessionId = sessionId
            
            // Try to find the verse in loaded verses
            if let verse = viewModel.verses.first(where: { 
                $0.verseNumber == session.verseNumber && 
                $0.book == session.book && 
                $0.chapter == session.chapter 
            }) {
                chatVerse = verse
                showChatSheet = true
            } else {
                // Verse not loaded yet, wait for verses to load or try loading it
                Task {
                    // Wait a bit for verses to load if chapter is being loaded
                    var attempts = 0
                    while attempts < 10 {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                        
                        if let verse = viewModel.verses.first(where: { 
                            $0.verseNumber == session.verseNumber && 
                            $0.book == session.book && 
                            $0.chapter == session.chapter 
                        }) {
                            await MainActor.run {
                                chatVerse = verse
                                showChatSheet = true
                            }
                            return
                        }
                        
                        attempts += 1
                    }
                    
                    // If still not found, try loading the verse directly
                    await MainActor.run {
                        // Create a minimal verse from session data for chat purposes
                        // The chat will work with the session's verseText
                        if let bookObj = BibleData.book(named: session.book) {
                            // We'll use the session's verseText which is already stored
                            // The ChatViewModel will use this
                            let tempVerse = BibleVerse(
                                id: "\(session.book)-\(session.chapter)-\(session.verseNumber)",
                                book: session.book,
                                chapter: session.chapter,
                                verseNumber: session.verseNumber,
                                textBsb: session.verseText, // Use session text as fallback
                                textCuv: session.verseText,
                                textCu1: session.verseText,
                                textKjv: session.verseText,
                                textWeb: session.verseText,
                                textSpa: session.verseText,
                                textPor: session.verseText,
                                testament: bookObj.testament.rawValue
                            )
                            chatVerse = tempVerse
                            showChatSheet = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showViewSettings) {
            ReadingSettingsView(isPresented: $showViewSettings)
        }
        .fullScreenCover(isPresented: $showPrayerFlow) {
            // Pass the selected verse if available to skip verse selection
            if let selectedId = selectedVerseId,
               let verse = viewModel.verses.first(where: { $0.id == selectedId }) {
                PrayerFlowView(initialVerse: verse)
            } else {
                PrayerFlowView()
            }
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
        .overlay {
            // Related Verses drawer (slides from right)
            if showRelatedVersesSheet, let verse = relatedVerse {
                ZStack {
                    // Background overlay - full screen, fades in/out
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showRelatedVersesSheet = false
                                relatedVersesOffset = UIScreen.main.bounds.width
                            }
                        }
                        .transition(.opacity)
                    
                    // Related Verses View - slides from right
                    HStack {
                        Spacer()
                        RelatedVersesSheet(
                            book: verse.book,
                            chapter: verse.chapter,
                            verse: verse.verseNumber,
                            verseText: verse.text(for: settingsStore.primaryLanguage),
                            settingsStore: settingsStore,
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showRelatedVersesSheet = false
                                    relatedVersesOffset = UIScreen.main.bounds.width
                                }
                            }
                        )
                        .environmentObject(router)
                        .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500), maxHeight: .infinity)
                        .offset(x: relatedVersesOffset)
                    }
                }
                .zIndex(1000)
                .onAppear {
                    // Reset offset and animate in
                    relatedVersesOffset = UIScreen.main.bounds.width
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        relatedVersesOffset = 0
                    }
                }
            }
            
            // Chapter Context drawer (slides from right)
            if showChapterContextSheet {
                ZStack {
                    // Background overlay - full screen, fades in/out
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showChapterContextSheet = false
                                chapterContextOffset = UIScreen.main.bounds.width
                            }
                        }
                        .transition(.opacity)
                    
                    // Chapter Context View - slides from right
                    if let book = book {
                        HStack {
                            Spacer()
                            ChapterInfoView(
                                book: book.name,
                                chapter: chapter ?? 1,
                                mode: .context,
                                settingsStore: settingsStore,
                                onDismiss: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showChapterContextSheet = false
                                        chapterContextOffset = UIScreen.main.bounds.width
                                    }
                                }
                            )
                            .environmentObject(router)
                            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500), maxHeight: .infinity)
                            .offset(x: chapterContextOffset)
                        }
                    }
                }
                .zIndex(1000)
                .onAppear {
                    // Reset offset and animate in
                    chapterContextOffset = UIScreen.main.bounds.width
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        chapterContextOffset = 0
                    }
                }
            }
            
            // Chapter Summary drawer (slides from right)
            if showChapterSummarySheet {
                ZStack {
                    // Background overlay - full screen, fades in/out
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showChapterSummarySheet = false
                                chapterSummaryOffset = UIScreen.main.bounds.width
                            }
                        }
                        .transition(.opacity)
                    
                    // Chapter Summary View - slides from right
                    if let book = book {
                        HStack {
                            Spacer()
                            ChapterInfoView(
                                book: book.name,
                                chapter: chapter ?? 1,
                                mode: .summary,
                                settingsStore: settingsStore,
                                onDismiss: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showChapterSummarySheet = false
                                        chapterSummaryOffset = UIScreen.main.bounds.width
                                    }
                                }
                            )
                            .environmentObject(router)
                            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500), maxHeight: .infinity)
                            .offset(x: chapterSummaryOffset)
                        }
                    }
                }
                .zIndex(1000)
                .onAppear {
                    // Reset offset and animate in
                    chapterSummaryOffset = UIScreen.main.bounds.width
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        chapterSummaryOffset = 0
                    }
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
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Path"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Verse number with save indicator
            HStack(spacing: 4) {
                Text("\(verse.verseNumber)")
                    .font(settingsStore.selectedFont.font(size: fontSize, weight: .semibold))
                    .foregroundColor(isSaved ? AppTheme.accentColor : AppTheme.verseNumberColor)
                
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
                        .font(settingsStore.selectedFont.font(size: fontSize))
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
                        .font(settingsStore.selectedFont.font(size: fontSize))
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
                    AppTheme.verseSelectionGradient
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
                    Label("Context", systemImage: "sparkles")
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
                Section(header: Text(settingsStore.appLanguage.localizedString("BibleTranslation"))) {
                    Picker(settingsStore.appLanguage.localizedString("PrimaryTranslation"), selection: $settingsStore.primaryLanguage) {
                        ForEach(Language.allCases.filter { $0 != .none }) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Picker(settingsStore.appLanguage.localizedString("SecondaryTranslation"), selection: $settingsStore.secondaryLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Toggle(settingsStore.appLanguage.localizedString("ShowSecondLanguage"), isOn: $settingsStore.showSecondaryLanguage)
                        .tint(AppTheme.accentColor)
                }
                
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
                
                Section(header: Text(settingsStore.appLanguage.localizedString("Font"))) {
                    Picker(selection: $settingsStore.selectedFont, label: Text(settingsStore.appLanguage.localizedString("Font"))) {
                        ForEach(AppFont.allCases) { font in
                            Text(font.localizedDisplayName(appLanguage: settingsStore.appLanguage))
                                .tag(font)
                        }
                    }
                    .pickerStyle(.menu)
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
                
            }
            .navigationTitle(settingsStore.appLanguage.localizedString("ReadingSettings"))
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
        .presentationDetents([.medium, .large])
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
                    .fill(AppTheme.cardGradient)
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
