// NameInputView - Step 2: Welcome + Name input with staggered cinematic reveal

import SwiftUI

struct NameInputView: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var isNameFieldFocused: Bool
    
    // MARK: - Animation States
    @State private var showParagraph = false
    @State private var paragraphDisplayed = ""
    @State private var showField = false
    @State private var showContinue = false
    
    private let paragraphFullText = "Your living path begins with a name.\nWhat should we call you?"
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Paragraph with typewriter
            paragraphText
                .padding(.bottom, 28)
            
            // Name field + continue (after typewriter completes)
            nameField
                .opacity(showField ? 1 : 0)
            
            Spacer()
            
            // Bottom navigation - continue button only (no back to welcome splash)
            HStack {
                Spacer()
                continueButton
                    .opacity(showContinue ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            startRevealSequence()
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startRevealSequence() {
        // Phase 1: Paragraph typewriter starts at t=0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showParagraph = true
            startParagraphTypewriter()
        }
    }
    
    private func startParagraphTypewriter() {
        let characters = Array(paragraphFullText)
        var index = 0
        let speed: TimeInterval = 0.055
        
        func typeNext() {
            guard index < characters.count else {
                // Typewriter complete — show name field + continue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showField = true
                        showContinue = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isNameFieldFocused = true
                    }
                }
                return
            }
            
            let char = String(characters[index])
            paragraphDisplayed += char
            index += 1
            
            // Pause longer on punctuation for natural rhythm
            var delay = speed
            if [".", "!", "?"].contains(char) {
                delay = speed * 6
            } else if [","].contains(char) {
                delay = speed * 3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        typeNext()
    }
    
    // MARK: - Paragraph (typewriter with fixed height)
    
    private var paragraphText: some View {
        ZStack(alignment: .top) {
            // Invisible full text to reserve the exact vertical space
            Text(paragraphFullText)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, 36)
                .hidden()
            
            // Visible typewriter text
            Text(paragraphDisplayed)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(AppTheme.onboardingText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, 36)
        }
        .opacity(showParagraph ? 1 : 0)
    }
    
    // MARK: - Name Field
    
    // Always English - language selection happens in Step 2
    private var placeholderText: String {
        return "Enter your name"
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(placeholderText, text: $state.name)
                .focused($isNameFieldFocused)
                .font(.system(size: 18))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.inputCornerRadius)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: AppTheme.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingDesign.inputCornerRadius)
                        .stroke(
                            isNameFieldFocused ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.2),
                            lineWidth: isNameFieldFocused ? 2 : 1
                        )
                )
                .autocapitalization(.words)
                .submitLabel(.next)
                .onSubmit {
                    if state.canProceed {
                        state.goNext()
                    }
                }
        }
        .padding(.horizontal, 36)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            if state.canProceed {
                state.goNext()
            }
        }) {
            Text("Next")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(AppTheme.buttonGradient)
                .cornerRadius(12)
        }
        .disabled(!state.canProceed)
        .opacity(state.canProceed ? 1.0 : 0.5)
    }
}
