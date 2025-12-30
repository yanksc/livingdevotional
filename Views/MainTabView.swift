// MainTabView - Main navigation with Tab Bar

import SwiftUI

struct MainTabView: View {
    @StateObject private var bibleViewModel = BibleViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        TabView(selection: Binding(
            get: { currentTab },
            set: { router.navigate(to: tabToRoute($0)) }
        )) {
            // Home Tab (placeholder for future)
            HomeView()
                .environmentObject(router)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Bible Tab
            BibleTabView(viewModel: bibleViewModel)
                .tabItem {
                    Label("Bible", systemImage: "book.fill")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(AppTheme.accentColor)
    }
    
    private var currentTab: Int {
        switch router.currentRoute {
        case .home: return 0
        case .bible, .reading: return 1
        case .settings, .profile: return 2
        default: return 1
        }
    }
    
    private func tabToRoute(_ tab: Int) -> AppRoute {
        switch tab {
        case 0: return .home
        case 1: return .bible
        case 2: return .settings
        default: return .bible
        }
    }
}

struct BibleTabView: View {
    @ObservedObject var viewModel: BibleViewModel
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BookListView(viewModel: viewModel)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .chapterGrid(let book):
                        ChapterGridView(book: book, viewModel: viewModel)
                    case .reading(let book, let chapter):
                        ReadingView(book: book, chapter: chapter, bibleViewModel: viewModel)
                    }
                }
        }
        .onChange(of: viewModel.selectedBook) { oldValue, newValue in
            // Update navigation path when book selection changes programmatically
            // (e.g., from toolbar back button or app resume)
            updateNavigationPath()
        }
        .onChange(of: viewModel.selectedChapter) { oldValue, newValue in
            // Update navigation path when chapter selection changes programmatically
            updateNavigationPath()
        }
        .onAppear {
            // If resuming from saved progress, build navigation path programmatically
            if viewModel.selectedBook != nil {
                updateNavigationPath()
            }
        }
    }
    
    private func updateNavigationPath() {
        // Calculate expected path count based on viewModel state
        let expectedCount = (viewModel.selectedBook != nil ? 1 : 0) + (viewModel.selectedChapter != nil ? 1 : 0)
        
        // Only update if path doesn't match expected state
        // This prevents unnecessary updates when NavigationLink or dismiss() already handled navigation
        if navigationPath.count != expectedCount {
            // Clear current path
            navigationPath.removeLast(navigationPath.count)
            
            // Build path based on current viewModel state
            if let book = viewModel.selectedBook {
                navigationPath.append(NavigationDestination.chapterGrid(book))
                
                if let chapter = viewModel.selectedChapter {
                    navigationPath.append(NavigationDestination.reading(book, chapter))
                }
            }
        }
    }
}

enum NavigationDestination: Hashable {
    case chapterGrid(BibleBook)
    case reading(BibleBook, Int)
}

#Preview {
    MainTabView()
}

