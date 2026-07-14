// SupporterInvitationView - Step 12: Mission-driven supporter invitation
// Full-screen step (not overlay). Screen 1: mission only. Screen 2: pricing (SupporterPricingView).

import SwiftUI

struct SupporterInvitationView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var showIcon = false
    @State private var showGreeting = false
    @State private var showMission = false
    @State private var missionComplete = false
    @State private var showActions = false
    @State private var showDismiss = false
    @State private var showPricing = false
    
    var body: some View {
        ZStack {
            if !showPricing {
                invitationContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
            
            if showPricing {
                SupporterPricingView(
                    state: state,
                    contextualHeader: nil,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showPricing = false
                        }
                    },
                    onDismiss: {
                        SettingsStore.shared.hasSeenOnboardingPaywall = true
                        withAnimation {
                            state.goNext()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .trailing)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showPricing)
        .onAppear {
            startRevealSequence()
        }
    }
    
    // MARK: - Screen 1: Invitation Content
    
    private var invitationContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            iconView
                .padding(.bottom, 20)
            
            greetingText
                .padding(.bottom, 16)
            
            missionText
                .padding(.bottom, 28)
            
            actionsView
                .opacity(showActions ? 1 : 0)
                .offset(y: showActions ? 0 : 10)
            
            Spacer()
            
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Icon
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentColor.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
        }
        .scaleEffect(showIcon ? 1.0 : 0.6)
        .opacity(showIcon ? 1 : 0)
        .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Greeting
    
    private var greetingText: some View {
        Text(greetingLocalized)
            .font(.system(size: OnboardingDesign.promptFontSize, weight: .regular, design: .serif))
            .foregroundColor(AppTheme.onboardingText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .opacity(showGreeting ? 1 : 0)
            .offset(y: showGreeting ? 0 : 10)
    }
    
    private var greetingLocalized: String {
        let name = state.name.isEmpty ? "" : state.name.trimmingCharacters(in: .whitespaces)
        if state.isChinese {
            return name.isEmpty ? "與我們同行" : "\(name)，與我們同行"
        } else if state.isSpanish {
            return name.isEmpty ? "Camina este camino con nosotros" : "\(name), camina este camino con nosotros"
        } else {
            return name.isEmpty ? "Walk this path with us" : "\(name), walk this path with us"
        }
    }
    
    // MARK: - Mission Statement
    
    private var missionText: some View {
        ZStack(alignment: .topLeading) {
            // Invisible full text reserves exact vertical space
            Text(missionLocalized)
                .font(.system(size: 17, weight: OnboardingDesign.promptFontWeight, design: OnboardingDesign.promptFontDesign))
                .lineSpacing(8)
                .padding(.horizontal, OnboardingDesign.horizontalPadding)
                .hidden()
            
            TypewriterText(
                text: missionLocalized,
                fontSize: 17,
                isChinese: state.isChinese
            ) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showActions = true
                    }
                }
            }
        }
        .opacity(showMission ? 1 : 0)
    }
    
    private var missionLocalized: String {
        if state.isChinese {
            return "Living Path 的使命是幫助每個人遇見神的話語，無論語言，無論信仰階段。你的支持讓我們能持續這個使命，將聖經帶到世界各地更多人的心中。"
        } else if state.isSpanish {
            return "Living Path existe para ayudar a todos a encontrar la Palabra de Dios, en cada idioma, en cada etapa de fe. Tu apoyo nos ayuda a continuar esta misión y llevar las Escrituras a más corazones en todo el mundo."
        } else {
            return "Living Path exists to help everyone encounter God's Word, in every language, at every stage of faith. Your support helps us continue this mission and bring Scripture to more hearts around the world."
        }
    }
    
    // MARK: - Actions (CTA + Dismiss)
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Pause 2 seconds before transitioning to pricing
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showPricing = true
                    }
                }
            }) {
                Text(ctaLocalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button(action: skipAndContinue) {
                Text(dismissLocalized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.vertical, 8)
            }
            .opacity(showDismiss ? 1 : 0)
            .animation(.easeIn(duration: 0.4), value: showDismiss)
        }
        .padding(.horizontal, 36)
    }
    
    private var ctaLocalized: String {
        if state.isChinese { return "開始免費試用" }
        if state.isSpanish { return "Iniciar prueba gratuita" }
        return "Start Free Trial"
    }
    
    private var dismissLocalized: String {
        if state.isChinese { return "之後再說" }
        if state.isSpanish { return "Quizás más tarde" }
        return "Not right now"
    }
    
    private func skipAndContinue() {
        SettingsStore.shared.hasSeenOnboardingPaywall = true
        withAnimation {
            state.goNext()
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startRevealSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                showIcon = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showGreeting = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showMission = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            showDismiss = true
        }
    }
}
