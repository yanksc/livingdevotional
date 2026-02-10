// RelatedVersesView - Step 7: AI-personalized related verses based on deep dive selection

import SwiftUI

struct RelatedVersesView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var showPrompt = false
    @State private var visibleVerseIndices: Set<Int> = []
    @State private var showContinue = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Prompt
            if showPrompt {
                VStack(spacing: 8) {
                    Text(promptText)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
            
            if state.isGeneratingVerses {
                loadingView
            } else if let verses = state.relatedVerses, !verses.isEmpty {
                versesListView(verses: verses)
            } else if state.versesError != nil {
                errorView
            }
            
            Spacer()
            
            // Bottom navigation bar
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
                continueButton
            }
            .padding(.horizontal, 24)
            .opacity(showContinue ? 1 : 0)
        }
        .padding(.bottom, 40)
        .onAppear {
            handleAppear()
        }
        .onChange(of: state.relatedVerses) { _, newVerses in
            // When verses are loaded asynchronously, animate them in
            if let verses = newVerses, visibleVerseIndices.isEmpty {
                animateVersesIn(count: verses.count)
            }
        }
    }
    
    // MARK: - Prompt Text
    
    private var promptText: String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        if state.isChinese {
            return "\(name)這些經文可能對你說話..."
        } else if state.isSpanish {
            return "\(name)estos versículos podrían hablarte..."
        } else {
            return "\(name)these verses may speak to you..."
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            BreathingDotsView()
            
            Text(loadingText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    private var loadingText: String {
        if state.isChinese {
            return "正在為你尋找經文..."
        } else if state.isSpanish {
            return "Buscando versículos para ti..."
        } else {
            return "Finding verses for you..."
        }
    }
    
    // MARK: - Verses List
    
    private func versesListView(verses: [OnboardingRecommendedVerse]) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ForEach(Array(verses.enumerated()), id: \.element.reference) { index, verse in
                    if visibleVerseIndices.contains(index) {
                        verseCard(verse: verse)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func verseCard(verse: OnboardingRecommendedVerse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Verse text
            Text(verse.text)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            // Reference
            Text("— \(verse.reference)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.accentColor)
            
            // Reason - why this verse is recommended
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.8))
                    .padding(.top, 2)
                
                Text(verse.reason)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.95))
                .shadow(color: AppTheme.accentColor.opacity(0.1), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.accentColor.opacity(0.1), lineWidth: 1)
        )
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
                state.generateRelatedVerses()
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
        // Show prompt first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showPrompt = true
            }
        }
        
        // If verses already loaded, animate them in
        if let verses = state.relatedVerses {
            animateVersesIn(count: verses.count)
        }
    }
    
    private func animateVersesIn(count: Int) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    _ = visibleVerseIndices.insert(i)
                }
                
                // Show continue after last verse
                if i == count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showContinue = true
                        }
                    }
                }
            }
        }
    }
}
