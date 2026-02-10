// DeepDiveQuestionView - Step 7: AI-generated question for personalized exploration

import SwiftUI

struct DeepDiveQuestionView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var showQuestion = false
    @State private var visibleOptionIndices: Set<Int> = []
    @State private var showOtherInput = false
    @State private var otherInputText = ""
    @State private var showContinue = false
    @State private var showNavigation = false
    @FocusState private var isOtherInputFocused: Bool
    
    // Reserve space for question text
    private let questionReservedHeight: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Question text - left aligned with reserved space
                    questionTextView
                        .padding(.top, 40)
                    
                    if state.isGeneratingDeepDive {
                        loadingView
                    } else if let question = state.deepDiveQuestion {
                        optionsView(question: question)
                    } else if state.deepDiveError != nil {
                        errorView
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Bottom navigation bar
            HStack {
                OnboardingBackButton(state: state)
                    .opacity(showNavigation ? 1 : 0)
                Spacer()
                continueButton
                    .opacity(showContinue ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            handleAppear()
        }
        .onChange(of: state.deepDiveQuestion) { _, newQuestion in
            if newQuestion != nil && !showQuestion {
                handleAppear()
            }
        }
    }
    
    // MARK: - Question Text
    
    private var questionTextView: some View {
        Group {
            if showQuestion, let question = state.deepDiveQuestion {
                Text(questionWithName(question.question))
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, minHeight: questionReservedHeight, alignment: .topLeading)
            } else {
                Color.clear
                    .frame(height: questionReservedHeight)
            }
        }
    }
    
    private func questionWithName(_ question: String) -> String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        // If question already starts with user's name, don't duplicate
        if question.lowercased().hasPrefix(state.name.lowercased()) {
            return question
        }
        return name + question.prefix(1).lowercased() + String(question.dropFirst())
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            BreathingDotsView()
            
            Text(loadingText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.vertical, 40)
    }
    
    private var loadingText: String {
        if state.isChinese {
            return "正在為你準備問題..."
        } else if state.isSpanish {
            return "Preparando una pregunta para ti..."
        } else {
            return "Preparing a question for you..."
        }
    }
    
    // MARK: - Options View
    
    private func optionsView(question: DeepDiveQuestion) -> some View {
        VStack(spacing: 16) {
            // 4 AI-generated options
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                if visibleOptionIndices.contains(index) {
                    optionButton(option: option, index: index)
                        .opacity(visibleOptionIndices.contains(index) ? 1 : 0)
                }
            }
            
            // "Other" option
            if visibleOptionIndices.contains(4) {
                otherOptionView
                    .opacity(visibleOptionIndices.contains(4) ? 1 : 0)
            }
        }
    }
    
    private func optionButton(option: String, index: Int) -> some View {
        let isSelected = state.deepDiveSelection?.selectedOption == option
        
        return Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                state.selectDeepDiveOption(option)
                showOtherInput = false
                otherInputText = ""
                showContinue = true
            }
        }) {
            HStack {
                Text(option)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentColor : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    private var otherOptionView: some View {
        VStack(spacing: 12) {
            // "Other" button
            Button(action: {
                withAnimation(.easeOut(duration: 0.3)) {
                    showOtherInput.toggle()
                    if showOtherInput {
                        state.deepDiveSelection = nil
                        showContinue = false
                        isOtherInputFocused = true
                    }
                }
            }) {
                HStack {
                    Text(otherButtonText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(showOtherInput ? AppTheme.accentColor : AppTheme.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: showOtherInput ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showOtherInput ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.15), lineWidth: 1)
                )
            }
            
            // Text input for "Other"
            if showOtherInput {
                VStack(spacing: 8) {
                    TextField(otherPlaceholderText, text: $otherInputText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(16)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isOtherInputFocused)
                        .lineLimit(3...5)
                        .onChange(of: otherInputText) { _, newValue in
                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                state.setDeepDiveCustomInput(newValue)
                                showContinue = true
                            } else {
                                state.deepDiveSelection = nil
                                showContinue = false
                            }
                        }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var otherButtonText: String {
        if state.isChinese {
            return "其他（自行輸入）"
        } else if state.isSpanish {
            return "Otro (escribe tu respuesta)"
        } else {
            return "Other (share your own)"
        }
    }
    
    private var otherPlaceholderText: String {
        if state.isChinese {
            return "分享你想探索的方向..."
        } else if state.isSpanish {
            return "Comparte lo que te gustaría explorar..."
        } else {
            return "Share what you'd like to explore..."
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(errorText)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
            
            Button(action: {
                state.generateDeepDiveQuestion()
            }) {
                Text(retryText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var errorText: String {
        if state.isChinese {
            return "無法連線，請稍後再試"
        } else if state.isSpanish {
            return "Problema de conexión. Intenta de nuevo."
        } else {
            return "Connection issue. Please try again."
        }
    }
    
    private var retryText: String {
        if state.isChinese {
            return "重試"
        } else if state.isSpanish {
            return "Reintentar"
        } else {
            return "Retry"
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
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
        .disabled(state.deepDiveSelection == nil)
        .opacity(state.deepDiveSelection == nil ? 0.5 : 1.0)
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
    
    // MARK: - Appear Logic
    
    private func handleAppear() {
        if state.deepDiveQuestion != nil {
            // Show question first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showQuestion = true
                }
            }
            
            // Animate options in staggered
            animateOptionsIn()
        }
    }
    
    private func animateOptionsIn() {
        // Show 4 options + "Other" (5 total)
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.3)) {
                    _ = visibleOptionIndices.insert(i)
                }
            }
        }
        
        // Show navigation (back button) after all options animate in
        // Last option is at 0.6 + 4*0.15 = 1.2s, add buffer for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showNavigation = true
            }
        }
    }
}
