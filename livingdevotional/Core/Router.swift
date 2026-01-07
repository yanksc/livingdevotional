// Router - Centralized navigation and routing management

import SwiftUI

enum AppRoute: Hashable {
    case home
    case bible
    case reading(book: BibleBook, chapter: Int)
    case settings
    case profile
    case login
    case signup
}

class AppRouter: ObservableObject {
    @Published var currentRoute: AppRoute = .bible
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Int = 1 {
        didSet {
            // Update route based on selected tab
            // But preserve .reading routes when switching to Bible tab
            switch selectedTab {
            case 0: currentRoute = .home
            case 1:
                // Only set to .bible if not already a .reading route
                if case .reading = currentRoute {
                    // Keep the .reading route - don't overwrite it
                } else {
                    currentRoute = .bible
                }
            case 2: currentRoute = .settings
            default: currentRoute = .bible
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
    
    func navigateToReading(book: BibleBook, chapter: Int) {
        // Set route to reading, which will trigger MainTabView to update BibleViewModel
        currentRoute = .reading(book: book, chapter: chapter)
        selectedTab = 1 // Switch to Bible tab
    }
}


