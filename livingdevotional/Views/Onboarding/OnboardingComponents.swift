// OnboardingComponents - Shared UI components for onboarding views
// Edit this file to change common styles across all onboarding steps

import SwiftUI

// MARK: - Design Constants

/// Centralized design constants for easy tweaking
enum OnboardingDesign {
    // Typography
    static let promptFontSize: CGFloat = 26
    static let promptFontWeight: Font.Weight = .regular
    static let promptFontDesign: Font.Design = .serif
    
    static let buttonFontSize: CGFloat = 17
    static let buttonSelectedFontWeight: Font.Weight = .semibold
    static let buttonNormalFontWeight: Font.Weight = .regular
    
    // Spacing
    static let horizontalPadding: CGFloat = 32
    static let buttonVerticalPadding: CGFloat = 16
    static let buttonHorizontalPadding: CGFloat = 18
    static let buttonSpacing: CGFloat = 12
    
    // Corner Radius
    static let buttonCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    static let inputCornerRadius: CGFloat = 14
    
    // Animation Timing
    static let promptAppearDelay: Double = 0.3
    static let promptAnimationDuration: Double = 0.5
    static let optionStaggerDelay: Double = 0.12
    static let optionBaseDelay: Double = 0.7
    
    // Shadow
    static let selectedShadowRadius: CGFloat = 8
    static let normalShadowRadius: CGFloat = 3
    static let selectedShadowOpacity: Double = 0.25
    static let normalShadowOpacity: Double = 0.04
}

// MARK: - Selection Button Style

/// Reusable selection button for onboarding options
struct OnboardingSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(
                        size: OnboardingDesign.buttonFontSize,
                        weight: isSelected ? OnboardingDesign.buttonSelectedFontWeight : OnboardingDesign.buttonNormalFontWeight
                    ))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, OnboardingDesign.buttonVerticalPadding)
            .padding(.horizontal, OnboardingDesign.buttonHorizontalPadding)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: OnboardingDesign.buttonCornerRadius)
                            .fill(AppTheme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: OnboardingDesign.buttonCornerRadius)
                            .fill(Color.white.opacity(0.95))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.buttonCornerRadius)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.accentColor.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.accentColor.opacity(OnboardingDesign.selectedShadowOpacity) : Color.black.opacity(OnboardingDesign.normalShadowOpacity),
                radius: isSelected ? OnboardingDesign.selectedShadowRadius : OnboardingDesign.normalShadowRadius,
                x: 0,
                y: isSelected ? 3 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Primary Continue Button

/// Standard continue button for onboarding steps
struct OnboardingContinueButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.buttonGradient)
                .cornerRadius(OnboardingDesign.cardCornerRadius)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Secondary Skip Button

/// Skip/secondary action button
struct OnboardingSkipButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}

// MARK: - Back Button

/// Consistent back button for onboarding steps
struct OnboardingBackButton: View {
    @ObservedObject var state: OnboardingState
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.goBack()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text(backText)
                    .font(.system(size: 15, weight: .regular))
            }
            .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    private var backText: String {
        if state.isChinese {
            return "上一步"
        } else if state.isSpanish {
            return "Atrás"
        } else {
            return "Back"
        }
    }
}

// MARK: - Prompt Text

/// Standard prompt text style
struct OnboardingPromptText: View {
    let text: String
    var fontSize: CGFloat = OnboardingDesign.promptFontSize
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: OnboardingDesign.promptFontWeight, design: OnboardingDesign.promptFontDesign))
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Typewriter Text

/// Character-by-character typewriter animation for prompts
struct TypewriterText: View {
    let text: String
    let fontSize: CGFloat
    let isChinese: Bool
    var onComplete: (() -> Void)? = nil
    
    @State private var displayedText = ""
    @State private var isComplete = false
    @State private var hasStarted = false
    
    var body: some View {
        // Reserve fixed height to prevent vertical movement
        // Estimate max height: assume 3 lines max for longer prompts (with line spacing)
        let estimatedLineHeight = fontSize * 1.6  // Account for line spacing
        let maxHeight = estimatedLineHeight * 3
        
        Text(displayedText)
            .font(.system(size: fontSize, weight: OnboardingDesign.promptFontWeight, design: OnboardingDesign.promptFontDesign))
            .foregroundColor(AppTheme.onboardingText)
            .multilineTextAlignment(.leading)
            .lineSpacing(8)  // Increased line spacing for better readability
            .frame(maxWidth: .infinity, minHeight: maxHeight, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: false)
            .padding(.horizontal, OnboardingDesign.horizontalPadding)
            .onAppear {
                if !hasStarted {
                    startTypewriter()
                }
            }
            .onChange(of: text) { _, _ in
                // Reset when text changes
                hasStarted = false
                displayedText = ""
                isComplete = false
            }
    }
    
    private func startTypewriter() {
        guard !hasStarted else { return }
        hasStarted = true
        displayedText = ""
        isComplete = false
        let characters = Array(text)
        var index = 0
        let speed: TimeInterval = isChinese ? 0.05 : 0.03
        
        func typeNext() {
            guard index < characters.count else {
                isComplete = true
                onComplete?()
                return
            }
            
            let char = String(characters[index])
            displayedText += char
            index += 1
            
            var delay = speed
            // Pause longer on punctuation
            if [".", ",", "?", "!", "。", "，", "？", "！", "\n"].contains(char) {
                delay = speed * 4
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        // Small delay before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingDesign.promptAppearDelay) {
            typeNext()
        }
    }
}

// MARK: - Verse Card

/// Card for displaying Bible verses
struct OnboardingVerseCard: View {
    let verseText: String
    let reference: String
    var elevation: CardElevation = .normal
    
    enum CardElevation {
        case normal, elevated
        
        var shadowRadius: CGFloat {
            switch self {
            case .normal: return 20
            case .elevated: return 24
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .normal: return 0.15
            case .elevated: return 0.2
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(verseText)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            
            Text("— \(reference)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: AppTheme.accentColor.opacity(elevation.shadowOpacity), radius: elevation.shadowRadius, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accentColor.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Loading View

/// Breathing dots loading animation
struct OnboardingLoadingView: View {
    let message: String
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.4
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 10, height: 10)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: scale
                        )
                }
            }
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
        .onAppear {
            scale = 1.3
            opacity = 1.0
        }
    }
}

// MARK: - Error View

/// Standard error view with retry
struct OnboardingErrorView: View {
    let message: String
    let retryTitle: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
            
            Button(action: retryAction) {
                Text(retryTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(10)
            }
        }
    }
}
