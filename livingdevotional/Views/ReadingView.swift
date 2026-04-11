// ReadingView - Displays verses in a scrollable view with dual-language support
//
// Extracted components are in separate files:
// - Reading/VerseView.swift: Individual verse display
// - Reading/ReadingSettingsView.swift: Font/spacing/translation settings sheet
// - Reading/ReadingDrawerOverlays.swift: Reusable SlideOutDrawer component
//
// This view is organized into the following sections:
// - Properties: State, Environment, and ObservedObject properties
// - Initialization: View initializer
// - Computed Properties: Derived values from state
// - Navigation: Chapter navigation functions
// - Verse Actions: Copy, share, highlight operations
// - Data Loading: Verse loading and reading plan progress
// - Scroll Management: Scroll position and targeting
// - View Builders - State Views: Loading, error, empty states
// - View Builders - Content: Main content and verses
// - View Builders - Drawers: Slide-out panels
// - View Builders - Toolbar: Navigation bar items
// - View Builders - Sheets: Modal content
// - Event Handlers: Notification and lifecycle handlers
// - Body: Main view composition

import SwiftUI
import Foundation

struct ReadingView: View {
    
    // MARK: - Properties
    
    // External dependency
    let bibleViewModel: BibleViewModel?
    
    // View models and stores
    @StateObject private var viewModel = ReadingViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var planStore = ReadingPlanStore.shared
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    
    // Sheet presentation state
    @State private var showBookSelector = false
    @State private var showViewSettings = false
    @State private var showSaveSheet = false
    @State private var showChatSheet = false
    @State private var showPrayerFlow = false
    @State private var showRelatedVersesSheet = false
    @State private var showChapterContextSheet = false
    @State private var showChapterSummarySheet = false
    @State private var showVerseSearch = false
    @State private var showReadingHistory = false
    
    // Verse selection state
    @State private var selectedVerseId: String? = nil
    @State private var chatVerse: BibleVerse?
    @State private var relatedVerse: BibleVerse?
    @State private var pendingChatSessionId: String?
    
    // Scroll state
    @State private var pendingScrollVerse: Int?
    @State private var pendingScrollBook: String?
    @State private var pendingScrollChapter: Int?
    @State private var pendingScrollRetry: Int = 0
    @State private var hasCompletedInitialScroll: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var usedNearEndScroll: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // Drawer animation offsets
    @State private var chapterContextOffset: CGFloat = UIScreen.main.bounds.width
    @State private var chapterSummaryOffset: CGFloat = UIScreen.main.bounds.width
    @State private var relatedVersesOffset: CGFloat = UIScreen.main.bounds.width
    
    // Zen Mode - Auto-hiding UI
    @State private var isToolbarVisible = true
    @State private var isTabBarVisible = true
    
    // AI Panel state
    @State private var showAIPanel: String? = nil
    @State private var aiPanelMode: AIMode = .insight
    
    // MARK: - Initialization
    
    init(book: BibleBook, chapter: Int, bibleViewModel: BibleViewModel? = nil) {
        self.bibleViewModel = bibleViewModel
        if let vm = bibleViewModel {
            self._pendingScrollVerse = State(initialValue: vm.targetVerse)
            self._pendingScrollBook = State(initialValue: vm.selectedBook?.name)
            self._pendingScrollChapter = State(initialValue: vm.selectedChapter)
        }
    }
    
    // MARK: - Computed Properties
    
    private var book: BibleBook? {
        bibleViewModel?.selectedBook
    }
    
    private var chapter: Int? {
        bibleViewModel?.selectedChapter
    }
    
    private var currentBookIndex: Int? {
        guard let book = book else { return nil }
        return BibleData.books.firstIndex(where: { $0.name == book.name })
    }
    
    private var chapterText: String {
        guard let chapter = chapter else { return "" }
        let chapterPrefix = BibleData.localizedChapterText(language: settingsStore.primaryLanguage)
        return chapterPrefix == "第" ? "\(chapterPrefix)\(chapter)章" : "\(chapterPrefix) \(chapter)"
    }
    
    private var shouldUseEagerLoading: Bool {
        (pendingScrollVerse != nil && !hasCompletedInitialScroll) || usedNearEndScroll
    }
    
    private var tabBarVisibility: Visibility {
        (isTabBarVisible && !showRelatedVersesSheet && !showChapterContextSheet && !showChapterSummarySheet) ? .visible : .hidden
    }
    
    // MARK: - Navigation
    
    private func navigateToNextChapter() {
        guard let book = book, let chapter = chapter, let currentIndex = currentBookIndex else { return }
        
        if chapter < book.chapters {
            bibleViewModel?.selectChapter(chapter + 1)
            reloadVersesIfReady()
        } else if currentIndex < BibleData.books.count - 1 {
            let nextBook = BibleData.books[currentIndex + 1]
            bibleViewModel?.selectBookAndChapter(nextBook, chapter: 1, targetVerse: nil)
            reloadVersesIfReady()
        }
    }
    
    private func navigateToPreviousChapter() {
        guard let chapter = chapter, let currentIndex = currentBookIndex else { return }
        
        if chapter > 1 {
            bibleViewModel?.selectChapter(chapter - 1)
            reloadVersesIfReady()
        } else if currentIndex > 0 {
            let previousBook = BibleData.books[currentIndex - 1]
            bibleViewModel?.selectBookAndChapter(previousBook, chapter: previousBook.chapters, targetVerse: nil)
            reloadVersesIfReady()
        }
    }
    
    // MARK: - Verse Actions
    
    private func copyVerse(_ verse: BibleVerse) {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        let copyText = "\"\(text)\"\n- \(reference)"
        
        DispatchQueue.global(qos: .userInitiated).async { [copyText] in
            UIPasteboard.general.string = copyText
        }
    }
    
    private func shareVerse(_ verse: BibleVerse) {
        let shareText = formatVerseForShare(verse)
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            DispatchQueue.main.async {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func highlightVerse(_ verse: BibleVerse) {
        if noteStore.isVerseSaved(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber) {
            noteStore.deleteVerse(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
        } else {
            noteStore.saveVerse(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber, content: "", labels: [], color: "yellow")
        }
    }
    
    private func formatVerseForShare(_ verse: BibleVerse) -> String {
        VerseShareFormatter.format(verse, language: settingsStore.primaryLanguage)
    }
    
    // MARK: - Data Loading
    
    private func reloadVersesIfReady() {
        selectedVerseId = nil
        showAIPanel = nil
        usedNearEndScroll = false
        
        if let book = bibleViewModel?.selectedBook, let chapter = bibleViewModel?.selectedChapter {
            Task { @MainActor in
                await viewModel.loadVerses(book: book.name, chapter: chapter)
            }
            updateReadingPlanProgress(book: book.name, chapter: chapter)
        }
    }
    
    private func updateReadingPlanProgress(book: String, chapter: Int) {
        for plan in planStore.plans {
            guard let progress = planStore.getProgress(for: plan.id), progress.isStarted else { continue }
            
            for day in plan.days where day.book == book && day.chapter == chapter {
                planStore.completeDay(plan.id, dayNumber: day.dayNumber)
                break
            }
        }
    }
    
    // MARK: - Scroll Management
    
    private func isVerseNearEnd(_ verseNumber: Int) -> Bool {
        guard !viewModel.verses.isEmpty else { return false }
        let lastVerseNumber = viewModel.verses.last?.verseNumber ?? 0
        return verseNumber > (lastVerseNumber - 4)
    }
    
    // MARK: - View Builders - Verses Content
    
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
                        onHighlight: {
                            highlightVerse(verse)
                        },
                        onShare: {
                            shareVerse(verse)
                        },
                        onAIInsight: {
                            if !UsageLimitStore.shared.canUseAIQuestion() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                                return
                            }
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
                            if !UsageLimitStore.shared.canUseAIQuestion() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                                return
                            }
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
                            if !UsageLimitStore.shared.canUseAIQuestion() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                                return
                            }
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
    
    // MARK: - View Builders - State Views
    
    /// Loading state view
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(AppTheme.accentColor)
    }
    
    /// Error state view
    @ViewBuilder
    private func errorView(_ errorMessage: String) -> some View {
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
    }
    
    /// Empty state view
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText)
            Text("No verses found")
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Edge swipe gesture overlays for chapter navigation
    @ViewBuilder
    private var edgeSwipeOverlays: some View {
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
                            if horizontalAmount < -50 && abs(horizontalAmount) > abs(verticalAmount) {
                                navigateToNextChapter()
                            }
                        }
                )
        }
    }
    
    // MARK: - View Builders - Main Content
    
    /// Main scrollable verses content with scroll tracking
    @ViewBuilder
    private var versesScrollView: some View {
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
    }
    
    /// Main content view with all states
    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        } else if viewModel.verses.isEmpty {
            emptyView
        } else {
            ZStack {
                versesScrollView
                edgeSwipeOverlays
            }
        }
    }
    
    // MARK: - View Builders - Drawer Overlays
    
    /// Related Verses drawer overlay
    @ViewBuilder
    private var relatedVersesDrawer: some View {
        if showRelatedVersesSheet, let verse = relatedVerse {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRelatedVersesSheet = false
                            relatedVersesOffset = UIScreen.main.bounds.width
                        }
                    }
                    .transition(.opacity)
                
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
                relatedVersesOffset = UIScreen.main.bounds.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    relatedVersesOffset = 0
                }
            }
        }
    }
    
    /// Chapter Context drawer overlay
    @ViewBuilder
    private var chapterContextDrawer: some View {
        if showChapterContextSheet {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showChapterContextSheet = false
                            chapterContextOffset = UIScreen.main.bounds.width
                        }
                    }
                    .transition(.opacity)
                
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
                chapterContextOffset = UIScreen.main.bounds.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    chapterContextOffset = 0
                }
            }
        }
    }
    
    /// Chapter Summary drawer overlay
    @ViewBuilder
    private var chapterSummaryDrawer: some View {
        if showChapterSummarySheet {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showChapterSummarySheet = false
                            chapterSummaryOffset = UIScreen.main.bounds.width
                        }
                    }
                    .transition(.opacity)
                
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
                chapterSummaryOffset = UIScreen.main.bounds.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    chapterSummaryOffset = 0
                }
            }
        }
    }
    
    /// Combined drawer overlays
    @ViewBuilder
    private var drawerOverlays: some View {
        relatedVersesDrawer
        chapterContextDrawer
        chapterSummaryDrawer
    }
    
    // MARK: - View Builders - Toolbar
    
    /// Toolbar leading buttons (previous chapter + search)
    @ViewBuilder
    private var toolbarLeadingButton: some View {
        HStack(spacing: 8) {
            Button {
                navigateToPreviousChapter()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled((chapter ?? 1) == 1 && currentBookIndex == 0)
            
            Button {
                showVerseSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    /// Toolbar principal button
    @ViewBuilder
    private var toolbarPrincipalButton: some View {
        Button {
            showBookSelector = true
        } label: {
            HStack(spacing: 6) {
                if let book = book, let chapter = chapter {
                    Text("\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter)")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.accentColor)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// Toolbar trailing buttons: Aa (font), bookmark, next chapter
    @ViewBuilder
    private var toolbarTrailingButtons: some View {
        HStack(spacing: 8) {
            Button {
                showViewSettings = true
            } label: {
                Text("Aa")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.accentColor)
            }
            .buttonStyle(.plain)
            
            Button {
                showReadingHistory = true
            } label: {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppTheme.accentColor)
            }
            .buttonStyle(.plain)
            
            Button {
                navigateToNextChapter()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled((chapter ?? 0) == (book?.chapters ?? 0) && currentBookIndex == BibleData.books.count - 1)
        }
    }
    
    /// Core body content without modifiers
    @ViewBuilder
    private var coreBodyContent: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            mainContentView
        }
    }
    
    // MARK: - View Builders - Sheet Content
    
    /// Chat sheet content
    @ViewBuilder
    private var chatSheetContent: some View {
        if let verse = chatVerse, let aiService = services.aiService {
            ChatView(
                viewModel: ChatViewModel(
                    aiService: aiService,
                    book: verse.book,
                    chapter: verse.chapter,
                    verse: verse.verseNumber,
                    verseText: verse.text(for: settingsStore.primaryLanguage),
                    appLanguage: settingsStore.appLanguage,
                    sessionId: pendingChatSessionId,
                    onLimitReached: {
                        router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                    }
                ),
                settingsStore: settingsStore,
                onClose: {
                    showChatSheet = false
                    pendingChatSessionId = nil
                }
            )
            .environmentObject(router)
            .presentationDetents([.fraction(0.8), .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    /// Prayer flow sheet content
    @ViewBuilder
    private var prayerFlowContent: some View {
        Group {
            if let selectedId = selectedVerseId,
               let verse = viewModel.verses.first(where: { $0.id == selectedId }) {
                PrayerFlowView(initialVerse: verse)
            } else {
                PrayerFlowView()
            }
        }
        .environmentObject(router)
    }
    
    /// Save sheet content
    @ViewBuilder
    private var saveSheetContent: some View {
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
                noteStore.loadSavedVerses()
            }
        }
    }
    
    // MARK: - Event Handlers
    
    /// Handle chat session notification
    private func handleOpenChatSession(_ notification: Notification) {
        guard let sessionId = notification.userInfo?["sessionId"] as? String,
              let session = ChatStore.shared.getSession(id: sessionId),
              let sessionBook = session.book,
              let sessionChapter = session.chapter,
              let sessionVerseNumber = session.verseNumber else {
            return
        }
        
        pendingChatSessionId = sessionId
        
        if let verse = viewModel.verses.first(where: {
            $0.verseNumber == sessionVerseNumber &&
            $0.book == sessionBook &&
            $0.chapter == sessionChapter
        }) {
            chatVerse = verse
            showChatSheet = true
        } else {
            Task {
                await loadVerseForChatSession(session)
            }
        }
    }
    
    /// Load verse for chat session asynchronously
    private func loadVerseForChatSession(_ session: ChatSession) async {
        guard let sessionBook = session.book,
              let sessionChapter = session.chapter,
              let sessionVerseNumber = session.verseNumber else { return }
        
        var attempts = 0
        while attempts < 10 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            if let verse = viewModel.verses.first(where: {
                $0.verseNumber == sessionVerseNumber &&
                $0.book == sessionBook &&
                $0.chapter == sessionChapter
            }) {
                await MainActor.run {
                    chatVerse = verse
                    showChatSheet = true
                }
                return
            }
            attempts += 1
        }
        
        await MainActor.run {
            guard let bookName = session.book,
                  let chapterNum = session.chapter,
                  let verseNum = session.verseNumber,
                  let verseText = session.verseText,
                  let bookObj = BibleData.book(named: bookName) else { return }
            
            let tempVerse = BibleVerse(
                id: "\(bookName)-\(chapterNum)-\(verseNum)",
                book: bookName,
                chapter: chapterNum,
                verseNumber: verseNum,
                textBsb: verseText,
                textCuv: verseText,
                textCu1: verseText,
                textKjv: verseText,
                textWeb: verseText,
                textSpa: verseText,
                textPor: verseText,
                testament: bookObj.testament.rawValue
            )
            chatVerse = tempVerse
            showChatSheet = true
        }
    }
    
    /// Handle first onAppear - load saved verses and scroll
    private func handleInitialAppear() {
        noteStore.loadSavedVerses()
        if pendingScrollVerse == nil {
            if let targetVerse = bibleViewModel?.targetVerse {
                pendingScrollVerse = targetVerse
                pendingScrollBook = bibleViewModel?.selectedBook?.name
                pendingScrollChapter = bibleViewModel?.selectedChapter
                hasCompletedInitialScroll = false
            }
        }
        if let proxy = scrollProxy {
            attemptScrollToPendingVerse(proxy: proxy, reason: "onAppear-root")
        }
    }
    
    /// Handle target verse change
    private func handleTargetVerseChange(_ newTarget: Int?) {
        if newTarget != nil {
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
    
    /// Handle second onAppear - record reading progress
    private func handleReadingAppear() {
        CheckInStore.shared.recordReading()
        if let book = book, let chapter = chapter {
            updateReadingPlanProgress(book: book.name, chapter: chapter)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        coreBodyContent
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
            .toolbar(tabBarVisibility, for: .tabBar)
            .preferredColorScheme(.light)
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) { toolbarLeadingButton }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .principal) { toolbarPrincipalButton }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .navigationBarTrailing) { toolbarTrailingButtons }
                        .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) { toolbarLeadingButton }
                    ToolbarItem(placement: .principal) { toolbarPrincipalButton }
                    ToolbarItem(placement: .navigationBarTrailing) { toolbarTrailingButtons }
                }
            }
            .sheet(isPresented: $showBookSelector) {
                if let viewModel = bibleViewModel {
                    BookSelectionSheet(viewModel: viewModel, isPresented: $showBookSelector)
                }
            }
            .sheet(isPresented: $showChatSheet) { chatSheetContent }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatSession")), perform: handleOpenChatSession)
            .sheet(isPresented: $showViewSettings) {
                ReadingSettingsView(isPresented: $showViewSettings)
                    .environmentObject(router)
            }
            .sheet(isPresented: $showVerseSearch) {
                VerseSearchView(settingsStore: settingsStore)
                    .environmentObject(router)
            }
            .sheet(isPresented: $showReadingHistory) {
                MyRecordsSheet()
                    .environmentObject(router)
            }
            .fullScreenCover(isPresented: $showPrayerFlow) { prayerFlowContent }
            .sheet(isPresented: $showSaveSheet) { saveSheetContent }
            .overlay { drawerOverlays }
            .onAppear(perform: handleInitialAppear)
            .onChange(of: bibleViewModel?.selectedBook) { _, _ in reloadVersesIfReady() }
            .onChange(of: bibleViewModel?.selectedChapter) { _, _ in reloadVersesIfReady() }
            .onChange(of: bibleViewModel?.targetVerse) { _, newTarget in handleTargetVerseChange(newTarget) }
            .onAppear(perform: handleReadingAppear)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ReadingView(book: BibleData.books[45], chapter: 3)
    }
}
