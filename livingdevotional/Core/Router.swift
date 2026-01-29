// Router - Centralized navigation and routing management

import SwiftUI

enum AppRoute: Hashable {
    case explore
    case bible
    case reading(book: BibleBook, chapter: Int, verse: Int? = nil)
    case home
    case journey
    case settings
    case profile
    case login
    case signup
    case verseOfTheDay  // For widget deep link
}

class AppRouter: ObservableObject {
    @Published var currentRoute: AppRoute = .home
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Int = 2 {
        didSet {
            // Update route based on selected tab
            // But preserve .reading routes when switching to Bible tab
            switch selectedTab {
            case 0: currentRoute = .explore
            case 1:
                // Only set to .bible if not already a .reading route
                if case .reading = currentRoute {
                    // Keep the .reading route - don't overwrite it
                } else {
                    currentRoute = .bible
                }
            case 2: currentRoute = .home
            case 3: currentRoute = .journey
            case 4: currentRoute = .settings
            default: currentRoute = .home
            }
        }
    }
    
    // For showing verse of the day full screen from widget
    @Published var showVerseOfTheDayFullScreen = false
    
    func navigate(to route: AppRoute) {
        currentRoute = route
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func navigateToReading(book: BibleBook, chapter: Int, verse: Int? = nil) {
        // Set route to reading, which will trigger MainTabView to update BibleViewModel
        currentRoute = .reading(book: book, chapter: chapter, verse: verse)
        selectedTab = 1 // Switch to Bible tab
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle deep links from widgets
    /// URL scheme: livingpath://widget/{action}/{parameter}
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "livingpath" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // livingpath://widget/verse - Open verse of the day
        // livingpath://widget/home - Go to home tab
        // livingpath://widget/plan/{planId} - Open specific reading plan
        
        guard pathComponents.first == "widget", pathComponents.count >= 2 else {
            // Default: go to home
            selectedTab = 2
            return
        }
        
        let action = pathComponents[1]
        
        switch action {
        case "verse":
            // Go to home and show verse of the day full screen
            selectedTab = 2
            currentRoute = .home
            // Trigger showing the verse full screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showVerseOfTheDayFullScreen = true
            }
            
        case "home":
            selectedTab = 2
            currentRoute = .home
            
        case "plan":
            // Navigate to the reading plan
            if pathComponents.count >= 3 {
                let planId = pathComponents[2].removingPercentEncoding ?? pathComponents[2]
                navigateToReadingPlan(planId: planId)
            } else {
                // No plan specified, go to explore tab
                selectedTab = 0
                currentRoute = .explore
            }
            
        default:
            // Unknown action, go to home
            selectedTab = 2
            currentRoute = .home
        }
    }
    
    /// Navigate to a specific reading plan and its current day
    private func navigateToReadingPlan(planId: String) {
        // Go to explore tab first
        selectedTab = 0
        currentRoute = .explore
        
        // Find the plan and navigate to today's reading
        if let todayReading = ReadingPlanStore.shared.getTodayReading(for: planId),
           let book = BibleData.book(named: todayReading.book) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.navigateToReading(
                    book: book,
                    chapter: todayReading.chapter,
                    verse: todayReading.verseStart
                )
            }
        }
    }
}


