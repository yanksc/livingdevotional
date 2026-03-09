// PrayerAmenView - Step 12: Personalized opening prayer
// Reuses SerenePrayerBackground, verse display, PrayerTypewriterText, and AmenButton from PrayerFlowView

import SwiftUI

struct PrayerAmenView: View {
    @ObservedObject var state: OnboardingState
    var onComplete: () -> Void
    
    @State private var showVerse = false
    @State private var showPrayer = false
    @State private var showAmen = false
    
    var body: some View {
        ZStack {
            // Serene prayer background (same as PrayerFlowView)
            SerenePrayerBackground()
            
            // Main content
            VStack(spacing: 0) {
                if state.isGeneratingPrayer {
                    Spacer()
                    loadingView
                    Spacer()
                } else if let prayer = state.personalizedPrayer {
                    contentView(prayer: prayer)
                } else if state.prayerError != nil {
                    Spacer()
                    errorView
                    Spacer()
                }
            }
        }
        .onAppear {
            handleAppear()
        }
        .onChange(of: state.personalizedPrayer) { _, newPrayer in
            if newPrayer != nil && !showVerse {
                handleAppear()
            }
        }
    }
    
    // MARK: - Content View
    
    private func contentView(prayer: String) -> some View {
        VStack(spacing: 0) {
            // Verse display at the top - from Scripture Echo step
            if let echo = state.scriptureEcho {
                verseCard(echo: echo)
                    .padding(.top, 28)
                    .opacity(showVerse ? 1 : 0)
            }
            
            // Prayer text with typewriter animation (strip trailing Amen)
            if showPrayer {
                VStack(alignment: .leading, spacing: 0) {
                    PrayerTypewriterText(
                        text: stripTrailingAmen(prayer),
                        speed: state.isChinese ? 0.075 : 0.06,
                        font: .system(size: 16, weight: .regular, design: .serif),
                        onComplete: {
                            // Show Amen button when prayer completes
                            withAnimation(.easeIn(duration: 1.0)) {
                                showAmen = true
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .transition(.opacity)
            }
            
            Spacer()
            
            // Centered Amen button pinned at bottom (no back button - this is the final step)
            AmenButton(onComplete: {
                state.completeOnboarding()
                onComplete()
            })
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
            .opacity(showAmen ? 1 : 0)
        }
    }
    
    // MARK: - Strip Trailing Amen
    
    /// Remove trailing "Amen", "阿們", "Amén" from prayer text since button shows it
    private func stripTrailingAmen(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Common Amen endings to strip
        let amenVariants = [
            "Amen.", "Amen", "amen.", "amen",
            "阿們。", "阿們", "阿门。", "阿门",
            "Amén.", "Amén", "amén.", "amén"
        ]
        
        for variant in amenVariants {
            if result.hasSuffix(variant) {
                result = String(result.dropLast(variant.count))
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        return result
    }
    
    // MARK: - Verse Card
    
    private func verseCard(echo: ScriptureEchoResponse) -> some View {
        VStack(spacing: 8) {
            Text(echo.verseText)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
            
            Text("— \(echo.verseReference)")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .tint(.white.opacity(0.9))
            
            Text(loadingText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var loadingText: String {
        if state.isChinese {
            return "預備禱告中..."
        } else if state.isSpanish {
            return "Preparando una oración..."
        } else {
            return "Preparing a prayer..."
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(errorText)
                .font(.body)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding()
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Button(action: {
                state.generatePrayer()
            }) {
                Text(retryText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 32)
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
    
    // MARK: - Appear Logic
    
    private func handleAppear() {
        if state.personalizedPrayer != nil {
            // Show verse first with slow, gentle fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    showVerse = true
                }
                
                // Show prayer after verse fully fades in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showPrayer = true
                    }
                }
            }
        }
    }
}
