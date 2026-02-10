// ReflectionInputView - Step 4: Open reflection

import SwiftUI

struct ReflectionInputView: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var showTextField = false
    @State private var showContinue = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Prompt with typewriter effect
            TypewriterText(
                text: promptText,
                fontSize: 22,
                isChinese: state.isChinese
            ) {
                // After prompt completes, show text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showTextField = true
                    }
                    // Show continue after text field animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showContinue = true
                        }
                    }
                }
            }
            
            // Text input area - always rendered, opacity-based
            textInputArea
                .opacity(showTextField ? 1 : 0)
            
            Spacer()
            
            // Bottom navigation bar
            HStack {
                OnboardingBackButton(state: state)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    state.goNext()
                }) {
                    Text(continueButtonText)
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
            .padding(.horizontal, 24)
            .opacity(showContinue ? 1 : 0)
        }
        .padding(.bottom, 40)
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Text Content
    
    private var promptText: String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        if state.isChinese {
            return "\(name)在你的信仰旅程中，\n有什麼想要成長或更深入了解的？"
        } else if state.isSpanish {
            return "\(name)en tu camino de fe,\n¿qué te gustaría crecer o entender mejor?"
        } else {
            return "\(name)in your journey of faith,\nwhat would you like to grow in or understand better?"
        }
    }
    
    private var placeholderText: String {
        if state.isChinese {
            return "例如：更深的平安、更親近神、理解聖經..."
        } else if state.isSpanish {
            return "Por ejemplo: más paz, cercanía con Dios, entender la Biblia..."
        } else {
            return "For example: deeper peace, closeness with God, understanding Scripture..."
        }
    }
    
    private var continueButtonText: String {
        if state.isChinese {
            return "繼續"
        } else if state.isSpanish {
            return "Continuar"
        } else {
            return "Continue"
        }
    }
    
    // MARK: - Text Input Area
    
    private var textInputArea: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if state.reflection.isEmpty {
                    Text(placeholderText)
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                // TextEditor
                TextEditor(text: $state.reflection)
                    .focused($isTextFieldFocused)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: AppTheme.accentColor.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isTextFieldFocused ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.2),
                        lineWidth: isTextFieldFocused ? 2 : 1
                    )
            )
        }
        .padding(.horizontal, 24)
    }
    
}
