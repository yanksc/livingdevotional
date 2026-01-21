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
}


