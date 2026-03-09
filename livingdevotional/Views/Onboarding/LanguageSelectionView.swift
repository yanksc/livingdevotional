// LanguageSelectionView - Step 3: Language selection

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var visibleOptions: Set<Int> = []
    
    // Only show the three main languages
    private let displayedLanguages: [AppLanguage] = [.english, .chineseTraditional, .spanish]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Prompt with typewriter effect
            // Note: Keep in English since language not yet confirmed (prevents glitch when selecting)
            TypewriterText(
                text: promptText,
                fontSize: OnboardingDesign.promptFontSize,
                isChinese: false
            ) {
                // After prompt completes, start showing options
                animateOptionsIn()
            }
            
            // Language options - always rendered, opacity-based visibility
            VStack(spacing: OnboardingDesign.buttonSpacing) {
                ForEach(Array(displayedLanguages.enumerated()), id: \.element.id) { index, lang in
                    languageButton(lang)
                        .opacity(visibleOptions.contains(index) ? 1 : 0)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Bottom navigation - back button only (auto-advances on selection)
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Content
    
    private var promptText: String {
        // Always English - language not yet confirmed at this step
        let name = state.name.isEmpty ? "" : "\(state.name), "
        return "\(name)which language speaks to your heart?"
    }
    
    private func languageButton(_ lang: AppLanguage) -> some View {
        let isSelected = state.selectedLanguage == lang
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.selectedLanguage = lang
            }
            // Auto-advance after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                state.goNext()
            }
        }) {
            HStack {
                Text(displayName(for: lang))
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, OnboardingDesign.buttonVerticalPadding)
            .padding(.horizontal, 20)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: OnboardingDesign.cardCornerRadius)
                            .fill(AppTheme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: OnboardingDesign.cardCornerRadius)
                            .fill(Color.white.opacity(0.95))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.cardCornerRadius)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.accentColor.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.accentColor.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 10 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func displayName(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return "English"
        case .chineseTraditional: return "中文"
        case .spanish: return "Español"
        default: return lang.displayName
        }
    }
    
    // MARK: - Animation
    
    private func animateOptionsIn() {
        // Stagger language options fade-in
        for i in 0..<displayedLanguages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.30) {
                withAnimation(.easeOut(duration: 0.8)) {
                    _ = visibleOptions.insert(i)
                }
            }
        }
    }
}
