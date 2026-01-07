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
    
    // Zen Mode - Auto-hiding toolbar
    @State private var isToolbarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // Floating Action Button
    @State private var showFABMenu = false
    
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
                bibleViewModel?.selectBookAndChapter(nextBook, chapter: 1)
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
                bibleViewModel?.selectBookAndChapter(previousBook, chapter: previousBook.chapters)
                reloadVersesIfReady()
            }
        }
    }
    
    private var chapterText: String {
        guard let chapter = chapter else { return "" }
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        if languageCode == "zh-Hant" {
            return "第\(chapter)章"
        } else {
            return "Chapter \(chapter)"
        }
    }
    
    private var navigationTitleText: String {
        if let book = book, let chapter = chapter {
            return "\(book.localizedName(for: settingsStore.appLanguage)) \(chapter)"
        }
        return "Bible"
    }
    
    // MARK: - Helper Functions
    
    private func copyVerse(_ verse: BibleVerse) {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        let copyText = "\"\(text)\"\n- \(reference)"
        
        // Close FAB menu with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showFABMenu = false
        }
        
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
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFABMenu = false
            }
            
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
        // Clear selected verse when navigating to a new chapter
        selectedVerseId = nil
        
        // Reload verses when both book and chapter are available
        if let book = bibleViewModel?.selectedBook,
           let chapter = bibleViewModel?.selectedChapter {
            Task { @MainActor in
                await viewModel.loadVerses(book: book.name, chapter: chapter)
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
                                        VerseView(
                                            verse: verse,
                                            settingsStore: settingsStore,
                                            fontSize: settingsStore.fontSize,
                                            isSelected: selectedVerseId == verse.id,
                                            onTap: {
                                                let wasSelected = selectedVerseId == verse.id
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                                    selectedVerseId = wasSelected ? nil : verse.id
                                                }
                                                // Close FAB menu when deselecting
                                                if wasSelected {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        showFABMenu = false
                                                    }
                                                }
                                            }
                                        )
                                        .id(verse.id)
                                    }
                                }
                                .padding(.bottom, 100) // Extra padding for FAB
                            }
                            .coordinateSpace(name: "scroll")
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
                        
                        // Floating Action Button (only show when verse is selected)
                        // IMPORTANT: Do NOT add .contentShape(Rectangle()) or .allowsHitTesting(true)
                        // to this container - it will block ALL touches on the screen!
                        if selectedVerseId != nil {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 16) {
                                        if showFABMenu {
                                            // Expanded menu items
                                            Group {
                                                if let selectedId = selectedVerseId,
                                                   let verse = viewModel.verses.first(where: { $0.id == selectedId }) {
                                                    // Copy verse button
                                                    FABMenuItem(
                                                        icon: "doc.on.doc",
                                                        label: "Copy Verse",
                                                        color: Color(red: 0.2, green: 0.6, blue: 0.4)
                                                    ) {
                                                        copyVerse(verse)
                                                    }
                                                    
                                                    // Share verse button
                                                    FABMenuItem(
                                                        icon: "square.and.arrow.up",
                                                        label: "Share Verse",
                                                        color: AppTheme.primaryBlue
                                                    ) {
                                                        shareVerse(verse)
                                                    }
                                                    
                                                    // AI Insight button
                                                    FABMenuItem(
                                                        icon: "sparkles",
                                                        label: "AI Insight",
                                                        color: AppTheme.primaryPurple
                                                    ) {
                                                        // TODO: Implement AI insight
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                            showFABMenu = false
                                                        }
                                                    }
                                                    
                                                    // Save Verse button
                                                    FABMenuItem(
                                                        icon: "bookmark.fill",
                                                        label: "Save Verse",
                                                        color: AppTheme.accentColor
                                                    ) {
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                            showFABMenu = false
                                                        }
                                                        // Small delay to allow menu to close smoothly
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            showSaveSheet = true
                                                        }
                                                    }
                                                }
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                        
                                        // Main FAB button
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showFABMenu.toggle()
                                            }
                                        } label: {
                                            Image(systemName: showFABMenu ? "xmark" : "plus")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 56, height: 56)
                                                .background(
                                                    Circle()
                                                        .fill(AppTheme.accentColor)
                                                        .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                                                )
                                        }
                                    }
                                    .padding(.trailing, 20)
                                    .padding(.bottom, 20)
                                }
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
        }
        .onChange(of: bibleViewModel?.selectedBook) { oldBook, newBook in
            reloadVersesIfReady()
        }
        .onChange(of: bibleViewModel?.selectedChapter) { oldChapter, newChapter in
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
