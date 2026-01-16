// AppTheme - Modern color scheme and styling utilities

import SwiftUI

struct AppTheme {
    // MARK: - Primary Colors
    // Warm Sand (#D4A574) - Primary Brand Color
    static let primaryBlue = Color(red: 0.831, green: 0.647, blue: 0.455)
    // Soft Beige (#E8D5B7) - Secondary Brand Color
    static let primaryPurple = Color(red: 0.910, green: 0.835, blue: 0.718)
    // Sage Green (#A8C5B8) - Accent Color
    static let accentColor = Color(red: 0.659, green: 0.773, blue: 0.722)
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.831, green: 0.647, blue: 0.455), // Warm Sand
            Color(red: 0.910, green: 0.835, blue: 0.718)  // Soft Beige
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Background: Warm Cream (#FAF7F2)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.980, green: 0.969, blue: 0.949), // Warm Cream
            Color(red: 0.980, green: 0.969, blue: 0.949)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 0.996, green: 0.992, blue: 0.988) // Very light cream
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [
            Color(red: 0.831, green: 0.647, blue: 0.455), // Warm Sand
            Color(red: 0.659, green: 0.773, blue: 0.722)  // Sage Green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let chapterButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.910, green: 0.835, blue: 0.718), // Soft Beige
            Color(red: 0.831, green: 0.647, blue: 0.455)  // Warm Sand
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let verseNumberColor = Color(red: 0.831, green: 0.647, blue: 0.455) // Warm Sand
    
    // MARK: - Background Colors
    static let cardBackground = Color.white
    static let sectionBackground = Color(red: 0.980, green: 0.969, blue: 0.949) // Warm Cream
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

