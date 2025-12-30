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
}

