// NameInputView - Step 1: Name input

import SwiftUI

struct NameInputView: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var isNameFieldFocused: Bool
    
    @State private var showField = false
    @State private var showContinue = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Prompt with typewriter effect
            // Note: Always English - language selection happens in Step 2
            TypewriterText(
                text: promptText,
                fontSize: 24,
                isChinese: false
            ) {
                // After typewriter completes, show field and continue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showField = true
                        showContinue = true
                    }
                    // Auto-focus after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isNameFieldFocused = true
                    }
                }
            }
            
            // Name field - always rendered, opacity-based visibility
            nameField
                .opacity(showField ? 1 : 0)
            
            Spacer()
            
            // Bottom navigation - continue button only (step 1 has no back)
            HStack {
                Spacer()
                continueButton
                    .opacity(showContinue ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Content
    
    // Always English - language selection happens in Step 2
    private var promptText: String {
        return "Your personal path through Scripture begins here.\nWhat's your name?"
    }
    
    // Always English - language selection happens in Step 2
    private var placeholderText: String {
        return "Enter your name"
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(placeholderText, text: $state.name)
                .focused($isNameFieldFocused)
                .font(.system(size: 20))
                .padding(18)
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
        .padding(.horizontal, 40)
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
