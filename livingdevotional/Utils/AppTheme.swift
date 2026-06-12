// AppTheme - Modern color scheme and styling utilities

import SwiftUI
import Foundation

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

    // Onboarding CTA — a softer, more sophisticated gradient that leans
    // toward cream. Muted warm sand easing into a light sand-beige, for a
    // calmer, more premium feel than the saturated sand→sage button.
    static let onboardingButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.847, green: 0.706, blue: 0.553), // Soft muted sand
            Color(red: 0.910, green: 0.835, blue: 0.718)  // Soft Beige (cream-leaning)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Text color for the onboarding CTA — warm dark brown keeps strong
    // contrast on the lighter cream button (white would wash out).
    static let onboardingButtonText = Color(red: 0.40, green: 0.31, blue: 0.22)
    
    // Chapter selection colors - using Serene Sands palette
    static let chapterButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.910, green: 0.835, blue: 0.718), // Soft Beige
            Color(red: 0.831, green: 0.647, blue: 0.455)  // Warm Sand
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let chapterButtonColor = Color(red: 0.831, green: 0.647, blue: 0.455)  // Warm Sand
    
    // Verse selection gradient
    static let verseSelectionGradient = LinearGradient(
        colors: [
            Color(red: 0.659, green: 0.773, blue: 0.722).opacity(0.15), // Sage Green
            Color(red: 0.831, green: 0.647, blue: 0.455).opacity(0.12)  // Warm Sand
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let verseNumberColor = Color(red: 0.831, green: 0.647, blue: 0.455) // Warm Sand
    
    // Serene text color for onboarding - softer, more contemplative
    // A warm, muted gray-brown that's gentler than pure black
    static let onboardingText = Color(red: 0.35, green: 0.32, blue: 0.30)
    
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

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

