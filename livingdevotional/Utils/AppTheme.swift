// AppTheme - Modern color scheme and styling utilities

import SwiftUI

struct AppTheme {
    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let primaryPurple = Color(red: 0.5, green: 0.3, blue: 0.8)
    static let accentColor = Color(red: 0.3, green: 0.5, blue: 0.9)
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.45, blue: 0.85),
            Color(red: 0.35, green: 0.55, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 1.0),
            Color(red: 0.95, green: 0.97, blue: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 0.99, green: 0.99, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.4, blue: 0.8),
            Color(red: 0.3, green: 0.5, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let chapterButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.45, blue: 0.85),
            Color(red: 0.35, green: 0.55, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let verseNumberColor = Color(red: 0.2, green: 0.4, blue: 0.8)
    
    // MARK: - Background Colors
    static let cardBackground = Color(red: 0.99, green: 0.99, blue: 1.0)
    static let sectionBackground = Color(red: 0.97, green: 0.98, blue: 1.0)
}

// MARK: - View Modifiers

struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.backgroundGradient)
    }
}

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
    
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}

