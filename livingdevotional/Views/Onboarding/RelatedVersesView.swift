// RelatedVersesView - Step 9: Your first Verse of the Day, personalized from onboarding

import SwiftUI

struct RelatedVersesView: View {
    @ObservedObject var state: OnboardingState
    
    // Animation states — sequenced: typewriter → label → card → reason → save + continue
    @State private var showTypewriter = false
    @State private var showVerseOfDayLabel = false
    @State private var showVerse = false
    @State private var showReason = false
    @State private var showSaveButton = false
    @State private var showContinue = false
    @State private var isSaved = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Typewriter prompt — pinned at top, never moves
            ZStack(alignment: .topLeading) {
                // Invisible full text to reserve the exact vertical space
                Text(promptText)
                    .font(.system(size: OnboardingDesign.promptFontSize, weight: OnboardingDesign.promptFontWeight, design: OnboardingDesign.promptFontDesign))
                    .lineSpacing(8)
                    .padding(.horizontal, OnboardingDesign.horizontalPadding)
                    .hidden()
                
                // Visible typewriter text
                if showTypewriter {
                    TypewriterText(
                        text: promptText,
                        fontSize: OnboardingDesign.promptFontSize,
                        isChinese: state.isChinese,
                        onComplete: {
                            onTypewriterComplete()
                        }
                    )
                    .padding(.horizontal, 8) // TypewriterText already has horizontal padding
                }
            }
            .padding(.top, 48)
            
            // "VERSE OF THE DAY" label — fades in after typewriter
            Text(titleText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.accentColor.opacity(0.8))
                .textCase(.uppercase)
                .tracking(2.0)
                .padding(.top, 12)
                .opacity(showVerseOfDayLabel ? 1 : 0)
            
            // Scrollable content area — verse card grows here without shifting the prompt
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 16)
                    
                    if state.isGeneratingVerses {
                        loadingView
                            .padding(.top, 24)
                    } else if let verses = state.relatedVerses, let verse = verses.first {
                        // Verse card — fades in after label
                        verseOfTheDayCard(verse: verse)
                            .opacity(showVerse ? 1 : 0)
                            .padding(.horizontal, 24)
                        
                        // Save to Notes button — appears after reason
                        if showSaveButton {
                            saveToNotesButton(verse: verse)
                                .padding(.top, 16)
                                .transition(.opacity)
                        }
                    } else if state.versesError != nil {
                        errorView
                    }
                    
                    Spacer()
                        .frame(height: 24)
                }
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
            .padding(.bottom, 40)
        }
        .onAppear {
            handleAppear()
        }
        .onChange(of: state.relatedVerses) { _, newVerses in
            if newVerses != nil && !showTypewriter {
                // Verse just loaded — start typewriter
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showTypewriter = true
                    }
                }
            } else if newVerses != nil && showTypewriter && !showVerse {
                // Typewriter already complete, animate verse in
                animateVerseIn()
            }
        }
    }
    
    // MARK: - Typewriter Complete → Trigger Sequential Animations
    
    private func onTypewriterComplete() {
        // Show "VERSE OF THE DAY" label
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                showVerseOfDayLabel = true
            }
        }
        
        // If verse already loaded, animate it in
        if state.relatedVerses != nil {
            animateVerseIn()
        }
    }
    
    // MARK: - Prompt Text (typewriter content)
    
    private var promptText: String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        if state.isChinese {
            return "\(name)這段經文為你預備"
        } else if state.isSpanish {
            return "\(name)este versículo es para ti"
        } else {
            return "\(name)this verse is chosen for you"
        }
    }
    
    // MARK: - Title Text
    
    private var titleText: String {
        if state.isChinese {
            return "今日經文"
        } else if state.isSpanish {
            return "Versículo del Día"
        } else {
            return "Verse of the Day"
        }
    }
    
    // MARK: - Verse of the Day Card
    
    private func verseOfTheDayCard(verse: OnboardingRecommendedVerse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Verse text
            Text(verse.text)
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
            
            // Reference
            Text("— \(verse.reference)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.accentColor)
            
            // Reason — why this verse was chosen
            if showReason {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.accentColor.opacity(0.7))
                        .padding(.top, 2)
                    
                    Text(verse.reason)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppTheme.accentColor.opacity(0.15), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accentColor.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Save to Notes Button
    
    private func saveToNotesButton(verse: OnboardingRecommendedVerse) -> some View {
        Button(action: {
            saveVerseToNotes(verse: verse)
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .medium))
                
                Text(saveButtonText)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSaved ? AppTheme.accentColor : AppTheme.secondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSaved ? AppTheme.accentColor.opacity(0.1) : Color.white.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(isSaved ? AppTheme.accentColor.opacity(0.3) : AppTheme.accentColor.opacity(0.15), lineWidth: 1)
            )
        }
        .disabled(isSaved)
    }
    
    private var saveButtonText: String {
        if isSaved {
            if state.isChinese { return "已儲存" }
            else if state.isSpanish { return "Guardado" }
            else { return "Saved to Notes" }
        } else {
            if state.isChinese { return "儲存至筆記" }
            else if state.isSpanish { return "Guardar en notas" }
            else { return "Save to Notes" }
        }
    }
    
    private func saveVerseToNotes(verse: OnboardingRecommendedVerse) {
        // Parse reference (e.g., "Psalm 46:10" or "Philippians 4:6-7")
        let parsed = parseVerseReference(verse.reference)
        
        NoteStore.shared.saveVerse(
            book: parsed.book,
            chapter: parsed.chapter,
            verse: parsed.verse,
            content: verse.reason,
            labels: ["Onboarding", "Verse of the Day"]
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isSaved = true
        }
    }
    
    /// Parse a reference like "Psalm 46:10" or "1 John 3:16" into components
    private func parseVerseReference(_ reference: String) -> (book: String, chapter: Int, verse: Int) {
        // Split from the last space to handle multi-word book names like "1 John"
        let trimmed = reference.trimmingCharacters(in: .whitespaces)
        
        // Find the last space before the chapter:verse part
        if let lastSpaceIndex = trimmed.lastIndex(of: " ") {
            let book = String(trimmed[trimmed.startIndex..<lastSpaceIndex])
            let chapterVerse = String(trimmed[trimmed.index(after: lastSpaceIndex)...])
            
            // Split "46:10" or "4:6-7"
            let parts = chapterVerse.split(separator: ":")
            if parts.count == 2 {
                let chapter = Int(parts[0]) ?? 1
                // Handle verse ranges like "6-7" — take the first verse
                let verseStr = String(parts[1]).split(separator: "-").first.map(String.init) ?? String(parts[1])
                let verse = Int(verseStr) ?? 1
                return (book, chapter, verse)
            }
        }
        
        // Fallback
        return (reference, 1, 1)
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
            return "正在為你挑選經文..."
        } else if state.isSpanish {
            return "Eligiendo un versículo para ti..."
        } else {
            return "Choosing a verse for you..."
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
        // Only start typewriter if verse is already loaded (not generating)
        // If still loading, onChange will trigger it when verse arrives
        if !state.isGeneratingVerses && state.relatedVerses != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showTypewriter = true
            }
        }
    }
    
    private func animateVerseIn() {
        // Verse card fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showVerse = true
            }
            
            // Show reason after verse settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showReason = true
                }
            }
            
            // Show save button
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSaveButton = true
                }
            }
            
            // Show continue navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showContinue = true
                }
            }
        }
    }
}
