// WidgetColors - Serene Sands color palette for widgets
//
// Matches the main app's AppTheme colors

import SwiftUI

extension Color {
    // MARK: - Primary Colors (Serene Sands Palette)
    
    /// Warm Sand (#D4A574) - Primary Brand Color
    static let widgetWarmSand = Color(red: 0.831, green: 0.647, blue: 0.455)
    
    /// Soft Beige (#E8D5B7) - Secondary Brand Color
    static let widgetSoftBeige = Color(red: 0.910, green: 0.835, blue: 0.718)
    
    /// Sage Green (#A8C5B8) - Accent Color
    static let widgetSageGreen = Color(red: 0.659, green: 0.773, blue: 0.722)
    
    /// Warm Cream (#FAF7F2) - Background Color
    static let widgetWarmCream = Color(red: 0.980, green: 0.969, blue: 0.949)
    
    /// Very Light Cream (#FFFDFB) - Card Background
    static let widgetCardBackground = Color(red: 0.996, green: 0.992, blue: 0.988)
    
    // MARK: - Gradients
    
    /// Primary gradient (Warm Sand to Soft Beige)
    static var widgetPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [widgetWarmSand, widgetSoftBeige],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Background gradient (Warm Cream)
    static var widgetBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [widgetWarmCream, widgetCardBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Card gradient (White to Very Light Cream)
    static var widgetCardGradient: LinearGradient {
        LinearGradient(
            colors: [.white, widgetCardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Serene overlay gradient for text readability on images
    static var widgetSereneOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.4),
                Color.black.opacity(0.2),
                Color.black.opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Widget-Specific Styles

struct WidgetStyles {
    /// Serif font for verse text
    static func verseFont(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }
    
    /// Reference font
    static func referenceFont(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
    
    /// Caption font
    static func captionFont(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}
