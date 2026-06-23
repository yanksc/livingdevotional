// MainTabView - Main navigation with Tab Bar

import SwiftUI

struct MainTabView: View {
    @StateObject private var bibleViewModel = BibleViewModel()
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared

    var body: some View {
        TabView(selection: Binding(
            get: { currentTab },
            set: { router.navigate(to: tabToRoute($0)) }
        )) {
            // Explore Tab (0)
            ExploreView()
                .environmentObject(router)
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(0)
            
            // Bible Tab (1)
            BibleTabView(viewModel: bibleViewModel)
                .environmentObject(router)
                .tabItem {
                    Label("Bible", systemImage: "book.fill")
                }
                .tag(1)
            
            // Today Tab (2)
            NavigationStack {
                HomeView()
            }
                .environmentObject(router)
                .environmentObject(bibleViewModel)
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(2)
            
            // Path Tab (3)
            JourneyView()
                .environmentObject(router)
                .tabItem {
                    Label("Path", systemImage: "road.lanes")
                }
                .tag(3)
        }
        .tint(AppTheme.accentColor)
        .toolbarBackground(AppTheme.backgroundGradient, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            backgroundManager.preloadExploreViewImages(
                categoryCount: AskCategoryStore.shared.categories.count,
                planIds: ReadingPlanStore.shared.plans.map { $0.id }
            )
        }
        .onChange(of: router.currentRoute) { oldRoute, newRoute in
            // Handle navigation to reading view
            if case .reading(let book, let chapter, let verse) = newRoute {
                bibleViewModel.selectBookAndChapter(book, chapter: chapter, targetVerse: verse)
                router.selectedTab = 1 // Switch to Bible tab
            }
        }
        .sheet(isPresented: $router.showSettings) {
            SettingsView()
                .environmentObject(router)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $router.showUsageLimitPaywall) {
            ZStack {
                SereneGradientBackground()
                    .ignoresSafeArea()
                
                SupporterFullPaywallView(
                    contextualHeader: router.usageLimitPaywallContext.isEmpty ? nil : router.usageLimitPaywallContext,
                    onDismiss: {
                        router.showUsageLimitPaywall = false
                        router.usageLimitPaywallContext = ""
                    }
                )
            }
        }
    }
    
    private var currentTab: Int {
        switch router.currentRoute {
        case .explore: return 0
        case .bible, .reading: return 1
        case .home: return 2
        case .journey: return 3
        default: return 2
        }
    }
    
    private func tabToRoute(_ tab: Int) -> AppRoute {
        switch tab {
        case 0: return .explore
        case 1: return .bible
        case 2: return .home
        case 3: return .journey
        default: return .home
        }
    }
}

struct BibleTabView: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var profileStore = UserProfileStore.shared
    @ObservedObject var planStore = ReadingPlanStore.shared
    @ObservedObject var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showBookSelector = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                // Show ReadingView if book and chapter are selected
                if let book = viewModel.selectedBook, let chapter = viewModel.selectedChapter {
                    ReadingView(book: book, chapter: chapter, bibleViewModel: viewModel)
                } else if let recommendedBooks = profileStore.profile.recommendedBooks, !recommendedBooks.isEmpty,
                          planStore.progress.isEmpty {
                    // Show recommended books only when no selection and no previous reading plan
                    RecommendedBooksStartView(
                        books: recommendedBooks,
                        viewModel: viewModel,
                        showBookSelector: $showBookSelector
                    )
                } else {
                    // Fallback placeholder when no selection and no recommendations
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        Text(placeholderText)
                            .font(.headline)
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Button(action: { showBookSelector = true }) {
                            Text(browseButtonText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(AppTheme.buttonGradient)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.selectedBook == nil || viewModel.selectedChapter == nil {
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ProfileAvatarButton { router.showSettings = true }
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ProfileAvatarButton { router.showSettings = true }
                        }
                    }
                }
            }
            .sheet(isPresented: $showBookSelector) {
                BookSelectionSheet(viewModel: viewModel, isPresented: $showBookSelector)
            }
        }
    }
    
    private var placeholderText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "選擇一卷書開始閱讀" : "Select a book to begin reading"
    }
    
    private var browseButtonText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "瀏覽聖經" : "Browse Bible"
    }
    
    private var navigationTitle: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "聖經" : "Bible"
    }
}

// MARK: - Recommended Books Start View

struct RecommendedBooksStartView: View {
    let books: [RecommendedBook]
    @ObservedObject var viewModel: BibleViewModel
    @Binding var showBookSelector: Bool
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject var profileStore = UserProfileStore.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(headerText)
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(subtitleText)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                // Book cards
                VStack(spacing: 16) {
                    ForEach(books, id: \.bookName) { book in
                        RecommendedBookCard(book: book) {
                            selectBook(book.bookName)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Browse all books button
                Button(action: { showBookSelector = true }) {
                    HStack {
                        Image(systemName: "books.vertical")
                        Text(browseAllText)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.vertical, 16)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var headerText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "可以從這裡開始" : "Begin your journey here"
    }
    
    private var subtitleText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "根據你分享的內容，這些書卷或許能陪伴你的旅程" : "Based on what you shared, these books may resonate with your journey"
    }
    
    private var browseAllText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "瀏覽所有書卷" : "Browse all books"
    }
    
    private var allBooks: [BibleBook] {
        viewModel.oldTestamentBooks + viewModel.newTestamentBooks
    }
    
    private func selectBook(_ bookName: String) {
        // Find the Bible book matching the name
        if let book = allBooks.first(where: { $0.name == bookName }) {
            viewModel.selectBook(book)
            // Start from chapter 1
            viewModel.selectChapter(1)
        } else {
            // If not found by exact name, try localized names
            for bibleBook in allBooks {
                if bibleBook.localizedName(for: settingsStore.appLanguage) == bookName ||
                   bibleBook.name.lowercased() == bookName.lowercased() {
                    viewModel.selectBook(bibleBook)
                    viewModel.selectChapter(1)
                    return
                }
            }
        }
    }
}

// MARK: - Recommended Book Card

struct RecommendedBookCard: View {
    let book: RecommendedBook
    let onTap: () -> Void
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject var profileStore = UserProfileStore.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizedBookName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                
                Text(displayIntro)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text(startReadingText)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: AppTheme.accentColor.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.accentColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Sanitized intro for display: no emojis, no [name], no leading "Name, "
    private var displayIntro: String {
        var result = book.personalizedIntro
        result = result.replacingOccurrences(of: "[name]", with: "", options: .caseInsensitive)
        let name = profileStore.profile.name
        if !name.isEmpty, result.hasPrefix("\(name), ") {
            result = String(result.dropFirst("\(name), ".count))
        }
        result = String(result.unicodeScalars.filter { !$0.properties.isEmoji })
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    private var localizedBookName: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        let chineseNames: [String: String] = [
            "Psalms": "詩篇",
            "Matthew": "馬太福音",
            "Philippians": "腓立比書",
            "John": "約翰福音",
            "Romans": "羅馬書",
            "Proverbs": "箴言"
        ]
        
        if isChinese, let chinese = chineseNames[book.bookName] {
            return chinese
        }
        return book.bookName
    }
    
    private var startReadingText: String {
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        return isChinese ? "開始閱讀" : "Start reading"
    }
}

enum NavigationDestination: Hashable {
    case chapterGrid(BibleBook)
    case reading(BibleBook, Int)
}

#Preview {
    MainTabView()
}
