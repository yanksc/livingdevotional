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
                .environmentObject(bibleViewModel)
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
        .onChange(of: router.currentRoute) { oldRoute, newRoute in
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let logEntry: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "MainTabView.onChange(currentRoute)",
                "message": "route changed",
                "data": [
                    "oldRoute": String(describing: oldRoute),
                    "newRoute": String(describing: newRoute),
                    "hypothesisId": "C"
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
            
            // Handle navigation to reading view
            if case .reading(let book, let chapter, let verse) = newRoute {
                // #region agent log
                let logEntry2: [String: Any] = [
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "location": "MainTabView.onChange(currentRoute)",
                    "message": "calling selectBookAndChapter",
                    "data": [
                        "book": book.name,
                        "chapter": chapter,
                        "verse": verse as Any,
                        "hypothesisId": "D"
                    ],
                    "sessionId": "debug-session"
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry2),
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
                
                bibleViewModel.selectBookAndChapter(book, chapter: chapter, targetVerse: verse)
                router.selectedTab = 1 // Switch to Bible tab
            }
        }
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
    @State private var showBookSelector = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Show ReadingView if book and chapter are selected
                if let book = viewModel.selectedBook, let chapter = viewModel.selectedChapter {
                    ReadingView(book: book, chapter: chapter, bibleViewModel: viewModel)
                } else {
                    // Placeholder when no selection
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        Text("Select a book to begin reading")
                            .font(.headline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Bible")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBookSelector) {
                BookSelectionSheet(viewModel: viewModel, isPresented: $showBookSelector)
            }
        }
        .onAppear {
            // Show book selector on first entry if no book/chapter selected
            if viewModel.selectedBook == nil && viewModel.selectedChapter == nil {
                showBookSelector = true
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

