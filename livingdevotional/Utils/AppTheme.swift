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

// MARK: - AppFont Extension

extension AppFont {
    var design: Font.Design {
        switch self {
        case .system:
            return .default
        case .serif:
            return .serif
        case .rounded:
            return .rounded
        default:
            return .serif
        }
    }
    
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system, .serif, .rounded:
            return .system(size: size, weight: weight, design: design)
        case .sourceHanSerifCN:
            return .custom("SourceHanSerifCN-Regular", size: size)
        case .sourceHanSerifTC:
            return .custom("SourceHanSerifTC-Regular", size: size)
        }
    }
}

