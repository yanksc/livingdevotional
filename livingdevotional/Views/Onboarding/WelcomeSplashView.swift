// WelcomeSplashView - Step 1: Brief welcome splash that sets the tone
// Single screen, no swipe. Subtitle + scripture quote + Get Started CTA.

import SwiftUI

struct WelcomeSplashView: View {
    @ObservedObject var state: OnboardingState
    
    // MARK: - Animation States
    @State private var showSubtitle = false
    @State private var subtitleDisplayed = ""
    @State private var showQuote = false
    @State private var showCTA = false
    
    private let subtitleFullText = "Your scripture journey begins here."
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()

            // Text block: subtitle + scripture quote, shifted down ~10%
            VStack(alignment: .center, spacing: 0) {
                subtitleText
                    .padding(.bottom, 20)

                scriptureQuote
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 80)

            Spacer()

            // Get Started CTA pinned to bottom
            getStartedButton
                .opacity(showCTA ? 1 : 0)
                .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            startRevealSequence()
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startRevealSequence() {
        // Phase 1: Subtitle typewriter starts at t=0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSubtitle = true
            startSubtitleTypewriter()
        }
    }
    
    private func startSubtitleTypewriter() {
        let characters = Array(subtitleFullText)
        var index = 0
        let speed: TimeInterval = 0.055
        
        func typeNext() {
            guard index < characters.count else {
                // Typewriter complete — show scripture quote
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showQuote = true
                    }
                    // After quote fades in, show Get Started button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showCTA = true
                        }
                    }
                }
                return
            }
            
            let char = String(characters[index])
            subtitleDisplayed += char
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
    
    // MARK: - Subtitle (Centered Typewriter)
    
    private var subtitleText: some View {
        ZStack(alignment: .center) {
            // Invisible full text to reserve the exact vertical space
            Text(subtitleFullText)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.clear)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .center)

            // Visible typewriter text
            Text(subtitleDisplayed)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(AppTheme.onboardingText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, alignment: .center)
        .opacity(showSubtitle ? 1 : 0)
    }
    
    // MARK: - Scripture Quote
    
    private var scriptureQuote: some View {
        VStack(spacing: 4) {
            Text("\u{201C}You make known to me the path of life\u{201D}")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(AppTheme.onboardingText.opacity(0.55))
                .multilineTextAlignment(.center)

            Text("— Psalm 16:11")
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(AppTheme.onboardingText.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
        .opacity(showQuote ? 1 : 0)
    }
    
    // MARK: - Get Started Button
    
    private var getStartedButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.goNext()
            }
        }) {
            Text("Get Started")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.onboardingButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.onboardingButtonGradient)
                .cornerRadius(OnboardingDesign.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingDesign.buttonCornerRadius)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                )
                .shadow(color: AppTheme.primaryBlue.opacity(0.22), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity)
    }
}
