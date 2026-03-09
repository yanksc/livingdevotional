// ScriptureEchoView - Step 6: AI-powered empathetic response and Bible verse

import SwiftUI

struct ScriptureEchoView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var showEcho = false
    @State private var displayedEcho = ""
    @State private var echoComplete = false
    @State private var showVerse = false
    @State private var showSaveButton = false
    @State private var showContinue = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Scrollable content area
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Top padding
                        Spacer()
                            .frame(height: 28)
                        
                        // Echo text area - flexible height
                        echoTextArea
                        
                        // Spacing between echo and verse
                        Spacer()
                            .frame(height: 32)
                        
                        // Verse card area
                        verseCardArea
                        
                        // Bottom padding for scroll
                        Spacer()
                            .frame(height: 24)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom navigation bar - fixed at bottom
                HStack {
                    OnboardingBackButton(state: state)
                    Spacer()
                    continueButton
                }
                .opacity(showContinue ? 1 : 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            // Loading overlay
            if state.isGeneratingEcho {
                loadingView
            }
            
            // Error overlay
            if state.echoError != nil && !state.isGeneratingEcho && state.scriptureEcho == nil {
                errorView
            }
        }
        .onAppear {
            handleAppear()
        }
        .onChange(of: state.scriptureEcho) { _, newEcho in
            // When echo is loaded asynchronously, trigger animations
            if newEcho != nil && !showEcho && !showVerse {
                handleAppear()
            }
        }
    }
    
    // MARK: - Echo Text Area
    
    private var echoTextArea: some View {
        // Echo text - flexible height, will grow as needed
        Group {
            if showEcho {
                Text(echoTextWithName)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Placeholder for minimum height when empty
                Color.clear
                    .frame(height: 60)
            }
        }
    }
    
    // MARK: - Verse Card Area
    
    private var verseCardArea: some View {
        VStack(spacing: 16) {
            if let echo = state.scriptureEcho {
                verseCard(echo: echo)
                    .opacity(showVerse ? 1 : 0)
                
                // Save button - appears 2 seconds after verse
                if showSaveButton {
                    saveVerseButton
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            } else {
                // Placeholder
                Color.clear
                    .frame(height: 150)
            }
        }
    }
    
    // MARK: - Save Verse Button
    
    private var saveVerseButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.saveVerse()
            }
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: state.didSaveVerse ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                Text(saveButtonText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(state.didSaveVerse ? AppTheme.accentColor : AppTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(state.didSaveVerse ? AppTheme.accentColor.opacity(0.1) : Color.white.opacity(0.8))
            )
            .overlay(
                Capsule()
                    .stroke(state.didSaveVerse ? AppTheme.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(state.didSaveVerse)
    }
    
    private var saveButtonText: String {
        if state.didSaveVerse {
            if state.isChinese {
                return "已收藏"
            } else if state.isSpanish {
                return "Guardado"
            } else {
                return "Saved"
            }
        } else {
            if state.isChinese {
                return "收藏這段經文"
            } else if state.isSpanish {
                return "Guardar versículo"
            } else {
                return "Save this verse"
            }
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
        switch state.resolvedLanguage {
        case .chineseTraditional: return "讓聖經的話語回應你的分享..."
        case .chineseSimplified: return "让圣经的话语回应你的分享..."
        case .spanish: return "Tomando un momento para reflexionar sobre tus palabras..."
        case .portuguese: return "Tomando um momento para refletir sobre suas palavras..."
        default: return "Taking a moment to reflect on your words..."
        }
    }
    
    // MARK: - Echo Text With Name
    
    private var echoTextWithName: String {
        let name = state.name.isEmpty ? "" : "\(state.name), "
        return name + displayedEcho
    }
    
    // MARK: - Verse Card
    
    private func verseCard(echo: ScriptureEchoResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(echo.verseText)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("— \(echo.verseReference)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: AppTheme.accentColor.opacity(0.15), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
                state.generateScriptureEcho()
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
    
    // MARK: - Typewriter Animation
    
    private func startEchoTypewriter(_ text: String) {
        displayedEcho = ""
        let characters = Array(text)
        var index = 0
        let speed: TimeInterval = state.isChinese ? 0.04 : 0.03
        
        func typeNext() {
            guard index < characters.count else {
                echoComplete = true
                // Show verse after echo completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showVerse = true
                    }
                    // Show save button 2 seconds after verse appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSaveButton = true
                        }
                    }
                    // Show continue button 0.5 seconds after verse appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showContinue = true
                        }
                    }
                }
                return
            }
            
            let char = String(characters[index])
            displayedEcho += char
            index += 1
            
            var delay = speed
            if [".", ",", "?", "!", "。", "，", "？", "！"].contains(char) {
                delay = speed * 4
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        typeNext()
    }
    
    // MARK: - On Appear Logic
    
    func handleAppear() {
        if let echo = state.scriptureEcho {
            if echo.echo == nil || echo.echo?.isEmpty == true {
                // No echo, show verse directly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showVerse = true
                    }
                    // Show save button 2 seconds after verse appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSaveButton = true
                        }
                    }
                    // Show continue button after verse appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showContinue = true
                        }
                    }
                }
            } else if let echoText = echo.echo {
                // Has echo, start typewriter animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showEcho = true
                    startEchoTypewriter(echoText)
                }
            }
        }
    }
}

// MARK: - Breathing Dots Loading Animation

struct BreathingDotsView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.4
    
    var body: some View {
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
        .onAppear {
            scale = 1.3
            opacity = 1.0
        }
    }
}
